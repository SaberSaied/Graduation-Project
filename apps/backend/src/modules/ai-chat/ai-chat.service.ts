import { prisma } from '../../config/database';
import { callAI } from '../../config/ai';
import { AppError } from '../../middleware/error.middleware';
import * as transactionsService from '../transactions/transactions.service';
import * as categoriesService from '../categories/categories.service';
import * as budgetsService from '../budgets/budgets.service';
import * as goalsService from '../goals/goals.service';

async function buildSystemPrompt(userId: string): Promise<string> {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  const [user, transactions, goals, budgets, allCategories] = await Promise.all([
    prisma.user.findUniqueOrThrow({ where: { id: userId } }),
    prisma.transaction.findMany({
      where: { userId, date: { gte: startOfMonth, lt: endOfMonth } },
      include: { category: true },
      orderBy: { date: 'desc' },
    }),
    prisma.goal.findMany({ where: { userId, status: 'IN_PROGRESS' } }),
    prisma.budget.findMany({
      where: { userId },
      include: { category: true },
    }),
    prisma.category.findMany({
      where: { OR: [{ userId }, { isDefault: true }] },
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
You are an expert financial advisor AI assistant for the "Finance Manager" app.
Your goal is to help users manage their money, track expenses, set budgets, and achieve savings goals.
You have access to the user's real financial data below. Use it to give accurate, personalized, and actionable advice. Be concise, warm, and clear.

You can now SEE images (like receipts or bills) and HEAR voice messages.
- If the user sends a receipt, automatically extract the amount, category, and items, and suggest adding it as a transaction using the ADD_TRANSACTION action.
- If the user sends a voice message, respond to it as if they had typed it.

You can perform actions by returning a JSON object.

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


AVAILABLE CATEGORIES:
- Expenses: ${allCategories.filter(c => c.type === 'EXPENSE').map(c => c.name).join(', ')}
- Income: ${allCategories.filter(c => c.type === 'INCOME').map(c => c.name).join(', ')}

You can help the user:
1. Understand their spending patterns
2. Give saving tips based on your data
3. Answer financial questions
4. Log transactions (expense/income) via natural language. 
   - CRITICAL: Automatically categorize the transaction based on its title or description. 
   - If "Uber" or "Lyft" -> Transportation.
   - If "Netflix" or "Spotify" -> Subscriptions.
   - If "KFC" or "Burger King" -> Food.
   - If "Salary" or "Paycheck" -> Salary.
   - Use your semantic understanding to pick the best matching category from AVAILABLE CATEGORIES.
   - If NO category fits, propose a new sensible one with a name, emoji icon, and color.

NATURAL LANGUAGE COMMANDS:
For specific actions, respond in this exact JSON format ONLY (no extra text). 
Generate sensible defaults for icons and colors if not provided (use emojis for icons).

1. ADD_TRANSACTION (expense/income):
{
  "action": "ADD_TRANSACTION",
  "data": {
    "type": "EXPENSE", // or "INCOME"
    "amount": 50,
    "currency": "${user.currency}",
    "category": "Food & Dining", // Categorize automatically
    "categoryIcon": "🍔", // Suggested icon for the category
    "categoryColor": "#FF7043", // Suggested color for the category
    "title": "Lunch at cafe",
    "date": "${new Date().toISOString()}"
  }
}

2. ADD_CATEGORY:
{
  "action": "ADD_CATEGORY",
  "data": {
    "name": "Gym",
    "icon": "🏋️",
    "color": "#4CAF50",
    "type": "EXPENSE" // or "INCOME"
  }
}

3. ADD_BUDGET:
{
  "action": "ADD_BUDGET",
  "data": {
    "category": "Food & Dining",
    "amount": 500,
    "currency": "${user.currency}"
  }
}

4. ADD_GOAL:
{
  "action": "ADD_GOAL",
  "data": {
    "title": "Buy a New Car",
    "targetAmount": 20000,
    "currency": "${user.currency}",
    "deadline": "${new Date(now.getFullYear(), now.getMonth() + 12, now.getDate()).toISOString()}",
    "description": "Saving for a Tesla",
    "icon": "🚗",
    "color": "#2196F3"
  }
}

For all other messages, respond normally in plain text.
`;
}

export async function processMessage(userId: string, message: string, sessionId?: string | null, file?: any) {
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
  const responseText = await callAI(fullPrompt, message, file);

  // Detect and process actions
  let actionResult = null;
  let displayMessage = responseText;

  // Function to extract JSON from text (in case AI adds filler)
  const extractJson = (text: string) => {
    try {
      return JSON.parse(text);
    } catch {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          return JSON.parse(jsonMatch[0]);
        } catch {
          return null;
        }
      }
      return null;
    }
  };

  const parsed = extractJson(responseText);
  
  if (parsed && parsed.action) {
    try {
      if (parsed.action === 'ADD_TRANSACTION') {
        let category = await prisma.category.findFirst({
          where: {
            name: { contains: parsed.data.category, mode: 'insensitive' },
            OR: [{ isDefault: true }, { userId }],
          },
        });

        // Auto-create category if it doesn't exist
        if (!category) {
          category = await prisma.category.create({
            data: {
              userId,
              name: parsed.data.category,
              icon: parsed.data.categoryIcon || '📁',
              color: parsed.data.categoryColor || '#9E9E9E',
              type: (parsed.data.type || 'EXPENSE').toUpperCase() as any,
              isDefault: false,
            },
          });
        }

        actionResult = await transactionsService.createTransaction(userId, {
          categoryId: category.id,
          type: (parsed.data.type || 'EXPENSE').toUpperCase() as any,
          amount: Number(parsed.data.amount),
          currency: parsed.data.currency || 'USD',
          title: parsed.data.title,
          date: parsed.data.date ? new Date(parsed.data.date) : new Date(),
        });
        displayMessage = `✅ Got it! I've added your ${category.name} ${parsed.data.type.toLowerCase()} of ${parsed.data.amount} ${parsed.data.currency || 'USD'}.`;
      } 
      else if (parsed.action === 'ADD_CATEGORY') {
        actionResult = await categoriesService.createCategory(userId, {
          name: parsed.data.name,
          icon: parsed.data.icon || '📁',
          color: parsed.data.color || '#9E9E9E',
          type: (parsed.data.type || 'EXPENSE').toUpperCase() as any,
        });
        displayMessage = `✅ Success! I've created the new category "${parsed.data.name}" for your ${parsed.data.type.toLowerCase()}s.`;
      }
      else if (parsed.action === 'ADD_BUDGET') {
        const category = await prisma.category.findFirst({
          where: {
            name: { contains: parsed.data.category, mode: 'insensitive' },
            OR: [{ isDefault: true }, { userId }],
          },
        });

        if (category) {
          actionResult = await budgetsService.createBudget(userId, {
            categoryId: category.id,
            amount: Number(parsed.data.amount),
            currency: parsed.data.currency,
          } as any);
          displayMessage = `✅ Budget set! Your limit for ${category.name} is now ${parsed.data.amount} ${parsed.data.currency}.`;
        } else {
          displayMessage = `I tried to set a budget, but I couldn't find the category "${parsed.data.category}".`;
        }
      }
      else if (parsed.action === 'ADD_GOAL') {
        actionResult = await goalsService.createGoal(userId, {
          title: parsed.data.title,
          targetAmount: Number(parsed.data.targetAmount),
          currency: parsed.data.currency,
          deadline: parsed.data.deadline ? new Date(parsed.data.deadline) : null,
          description: parsed.data.description,
          icon: parsed.data.icon || '🎯',
          color: parsed.data.color || '#2196F3',
        });
        displayMessage = `✅ Goal created! You're now tracking your goal: "${parsed.data.title}" with a target of ${parsed.data.targetAmount} ${parsed.data.currency}. Good luck!`;
      }
    } catch (e) {
      console.error('Error executing AI action:', e);
      // Fallback to response text if action fails
    }
  }

  // Save messages
  await prisma.chatMessage.createMany({
    data: [
      { chatSessionId: chatSessionId!, role: 'USER', content: message },
      { chatSessionId: chatSessionId!, role: 'ASSISTANT', content: displayMessage },
    ],
  });

  // Use the already parsed action type if available
  const actionType = (parsed && parsed.action) ? parsed.action : 'UNKNOWN';

  return {
    message: displayMessage,
    sessionId: chatSessionId,
    action: actionResult ? { type: actionType, data: actionResult } : null,
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

  const responseText = await callAI(systemPrompt, 'Analyze this transaction impact.');
  return { analysis: responseText };
}
