import { prisma } from '../../config/database';
import { callGemini } from '../../config/gemini';
import { AppError } from '../../middleware/error.middleware';
import * as transactionsService from '../transactions/transactions.service';

async function buildSystemPrompt(userId: string): Promise<string> {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  const [user, transactions, goals, budgets] = await Promise.all([
    prisma.user.findUniqueOrThrow({ where: { id: userId } }),
    prisma.transaction.findMany({
      where: { userId, date: { gte: startOfMonth, lt: endOfMonth } },
      include: { category: true },
      orderBy: { date: 'desc' },
    }),
    prisma.goal.findMany({ where: { userId, status: 'IN_PROGRESS' } }),
    prisma.budget.findMany({
      where: { userId, month: now.getMonth() + 1, year: now.getFullYear() },
      include: { category: true },
    }),
  ]);

  const totalIncome = transactions
    .filter((t) => t.type === 'INCOME')
    .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  const totalExpenses = transactions
    .filter((t) => t.type === 'EXPENSE')
    .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;

  // Top spending categories
  const categoryTotals = new Map<string, { name: string; total: number }>();
  transactions
    .filter((t) => t.type === 'EXPENSE')
    .forEach((t) => {
      const existing = categoryTotals.get(t.categoryId) || { name: t.category.name, total: 0 };
      existing.total += t.amountInBaseCurrency;
      categoryTotals.set(t.categoryId, existing);
    });

  const topCategories = [...categoryTotals.values()]
    .sort((a, b) => b.total - a.total)
    .slice(0, 5);

  const recentTx = transactions.slice(0, 10);

  // Budget status
  const budgetStatus = [];
  for (const budget of budgets) {
    const spent = transactions
      .filter((t) => t.type === 'EXPENSE' && t.categoryId === budget.categoryId)
      .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);
    budgetStatus.push({
      category: budget.category.name,
      spent: spent.toFixed(2),
      limit: budget.amount.toFixed(2),
      usagePercent: ((spent / budget.amount) * 100).toFixed(0),
    });
  }

  return `
You are FinanceAI, a personal financial advisor assistant inside a finance app.
You have access to the user's real financial data below. Use it to give accurate,
personalized, and actionable advice. Be concise, warm, and clear.

USER PROFILE:
- Name: ${user.name}
- Base Currency: ${user.currency}
- Financial Goal: ${user.financialGoal ?? 'Not set'}

THIS MONTH SUMMARY (${now.toLocaleString('default', { month: 'long', year: 'numeric' })}):
- Total Income: ${totalIncome.toFixed(2)} ${user.currency}
- Total Expenses: ${totalExpenses.toFixed(2)} ${user.currency}
- Net Balance: ${(totalIncome - totalExpenses).toFixed(2)} ${user.currency}
- Savings Rate: ${savingsRate.toFixed(0)}%

TOP SPENDING CATEGORIES:
${topCategories.map((c) => `- ${c.name}: ${c.total.toFixed(2)} ${user.currency} (${totalExpenses > 0 ? ((c.total / totalExpenses) * 100).toFixed(0) : 0}%)`).join('\n')}

RECENT TRANSACTIONS (last 10):
${recentTx.map((t) => `- ${t.date.toISOString().split('T')[0]}: ${t.type === 'EXPENSE' ? '-' : '+'}${t.amount} ${t.currency} [${t.category.name}] ${t.title}`).join('\n')}

SAVINGS GOALS:
${goals.map((g) => `- ${g.title}: ${g.savedAmount}/${g.targetAmount} ${g.currency} (${((g.savedAmount / g.targetAmount) * 100).toFixed(0)}%)`).join('\n')}

BUDGET STATUS:
${budgetStatus.map((b) => `- ${b.category}: spent ${b.spent}/${b.limit} ${user.currency} (${b.usagePercent}% used)`).join('\n')}

CAPABILITIES:
You can help the user:
1. Understand their spending patterns
2. Give saving tips based on their actual data
3. Answer financial questions
4. Log transactions via natural language (respond with JSON action)
5. Warn about overspending in specific categories

NATURAL LANGUAGE COMMANDS:
If the user says something like "add $50 food expense" or "I spent 20 on coffee",
respond in this exact JSON format ONLY (no extra text):
{
  "action": "ADD_TRANSACTION",
  "data": {
    "type": "EXPENSE",
    "amount": 50,
    "currency": "${user.currency}",
    "category": "Food & Dining",
    "title": "Food expense",
    "date": "${new Date().toISOString()}"
  }
}

For all other messages, respond normally in plain text.
`;
}

export async function processMessage(userId: string, message: string, sessionId?: string | null) {
  // Get or create session
  let chatSessionId = sessionId;

  if (!chatSessionId) {
    const session = await prisma.chatSession.create({
      data: {
        userId,
        title: message.substring(0, 50) + (message.length > 50 ? '...' : ''),
      },
    });
    chatSessionId = session.id;
  }

  // Build context (including history if available)
  let historyPrompt = "";
  if (chatSessionId) {
    const previousMessages = await prisma.chatMessage.findMany({
      where: { chatSessionId },
      orderBy: { createdAt: 'desc' },
      take: 6,
    });
    
    if (previousMessages.length > 0) {
      historyPrompt = "\nCONVERSATION HISTORY (recent first):\n" + 
        previousMessages.reverse().map(m => `${m.role}: ${m.content}`).join('\n') + "\n";
    }
  }

  const systemPrompt = await buildSystemPrompt(userId);
  const fullPrompt = historyPrompt ? `${systemPrompt}\n${historyPrompt}` : systemPrompt;
  const responseText = await callGemini(fullPrompt, message);

  // Detect transaction action
  let actionResult = null;
  let displayMessage = responseText;

  try {
    const parsed = JSON.parse(responseText);
    if (parsed.action === 'ADD_TRANSACTION') {
      // Find category by name
      const category = await prisma.category.findFirst({
        where: {
          name: { contains: parsed.data.category, mode: 'insensitive' },
          OR: [{ isDefault: true }, { userId }],
        },
      });

      if (category) {
        actionResult = await transactionsService.createTransaction(userId, {
          categoryId: category.id,
          type: parsed.data.type,
          amount: parsed.data.amount,
          currency: parsed.data.currency,
          title: parsed.data.title,
          date: new Date(parsed.data.date),
        });

        displayMessage = `✅ Got it! I've added your ${parsed.data.category} ${parsed.data.type.toLowerCase()} of ${parsed.data.amount} ${parsed.data.currency}.`;
      } else {
        displayMessage = `I understood you want to add a transaction, but I couldn't find the category "${parsed.data.category}". Please try with a valid category name.`;
      }
    }
  } catch {
    // Normal text response, not a JSON command
  }

  // Save messages
  await prisma.chatMessage.createMany({
    data: [
      { chatSessionId: chatSessionId!, role: 'USER', content: message },
      { chatSessionId: chatSessionId!, role: 'ASSISTANT', content: displayMessage },
    ],
  });

  return {
    message: displayMessage,
    sessionId: chatSessionId,
    action: actionResult ? { type: 'ADD_TRANSACTION', transaction: actionResult } : null,
  };
}

export async function getChatSessions(userId: string) {
  return prisma.chatSession.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    include: {
      messages: {
        take: 1,
        orderBy: { createdAt: 'desc' },
      },
    },
  });
}

export async function getChatSession(sessionId: string, userId: string) {
  const session = await prisma.chatSession.findFirst({
    where: { id: sessionId, userId },
    include: {
      messages: {
        orderBy: { createdAt: 'asc' },
      },
    },
  });

  if (!session) throw new AppError('Chat session not found', 404);
  return session;
}

export async function deleteChatSession(sessionId: string, userId: string) {
  const session = await prisma.chatSession.findFirst({ where: { id: sessionId, userId } });
  if (!session) throw new AppError('Chat session not found', 404);

  return prisma.chatSession.delete({ where: { id: sessionId } });
}

export async function simulateTransactionImpact(
  userId: string,
  data: { amount: number; categoryId: string; goalId?: string | null }
) {
  const now = new Date();
  
  const [user, category, budget, goal] = await Promise.all([
    prisma.user.findUnique({ where: { id: userId } }),
    prisma.category.findUnique({ where: { id: data.categoryId } }),
    prisma.budget.findFirst({
      where: { userId, categoryId: data.categoryId, month: now.getMonth() + 1, year: now.getFullYear() },
    }),
    data.goalId ? prisma.goal.findFirst({ where: { id: data.goalId, userId } }) : Promise.resolve(null),
  ]);

  if (!user || !category) throw new AppError('Invalid user or category', 400);

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  
  const transactions = await prisma.transaction.findMany({
    where: { userId, categoryId: data.categoryId, date: { gte: startOfMonth, lt: endOfMonth }, type: 'EXPENSE' },
  });
  
  const currentSpent = transactions.reduce((sum, t) => sum + t.amountInBaseCurrency, 0);
  const newSpent = currentSpent + data.amount;

  let budgetStatus = 'No budget set for this category.';
  if (budget) {
    const isOver = newSpent > budget.amount;
    budgetStatus = `Budget limit is ${budget.amount}. Currently spent: ${currentSpent}. Adding ${data.amount} will make total spent ${newSpent}. ${isOver ? 'This puts you OVER budget!' : 'This keeps you UNDER budget.'}`;
  }

  let goalStatus = 'No related goal selected.';
  if (goal) {
    const remaining = goal.targetAmount - goal.savedAmount;
    goalStatus = `Goal "${goal.title}": Target is ${goal.targetAmount}, currently saved ${goal.savedAmount}. Remaining: ${remaining}. Adding this expense means less money available to contribute toward this goal.`;
  }

  const systemPrompt = `
You are a concise financial advisor. The user is about to make an expense of ${data.amount} ${user.currency} in category "${category.name}".

BUDGET CONTEXT:
${budgetStatus}

GOAL CONTEXT:
${goalStatus}

Provide a short, friendly, and direct 2-sentence analysis of how this transaction impacts their budget and future goal progress. Do NOT output JSON, just plain text.
  `;

  const responseText = await callGemini(systemPrompt, 'Analyze this transaction impact.');
  return { analysis: responseText };
}
