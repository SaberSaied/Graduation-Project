import { prisma } from '../config/database';
import { callAI } from '../config/ai';

export interface Insight {
  type: 'warning' | 'tip' | 'achievement';
  title: string;
  message: string;
  icon: string;
}

export async function generateInsights(userId: string): Promise<Insight[]> {
  try {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;
    const currentYear = now.getFullYear();

    const [user, transactions, budgets, goals] = await Promise.all([
      prisma.user.findUniqueOrThrow({ where: { id: userId } }),
      prisma.transaction.findMany({
        where: {
          userId,
          date: {
            gte: new Date(currentYear, currentMonth - 1, 1),
            lt: new Date(currentYear, currentMonth, 1),
          },
        },
        include: { category: true },
      }),
      prisma.budget.findMany({
        where: { userId, month: currentMonth, year: currentYear },
        include: { category: true },
      }),
      prisma.goal.findMany({
        where: { userId, status: 'IN_PROGRESS' },
      }),
    ]);

    const totalIncome = transactions
      .filter((t) => t.type === 'INCOME')
      .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

    const totalExpenses = transactions
      .filter((t) => t.type === 'EXPENSE')
      .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

    const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;

    // Top categories for AI context
    const categoryTotals = new Map<string, { name: string; total: number }>();
    transactions
      .filter((t) => t.type === 'EXPENSE')
      .forEach((t) => {
        const existing = categoryTotals.get(t.categoryId) || { name: t.category.name, total: 0 };
        existing.total += t.amountInBaseCurrency;
        categoryTotals.set(t.categoryId, existing);
      });

    const topCategoriesStr = [...categoryTotals.values()]
      .sort((a, b) => b.total - a.total)
      .slice(0, 5)
      .map(c => `- ${c.name}: ${c.total.toFixed(2)}`)
      .join('\n');

    const budgetStatusStr = budgets.map(b => {
      const spent = transactions
        .filter(t => t.type === 'EXPENSE' && t.categoryId === b.categoryId)
        .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);
      return `- ${b.category.name}: spent ${spent.toFixed(2)} / limit ${b.amount.toFixed(2)}`;
    }).join('\n');

    const goalsStr = goals.map(g => `- ${g.title}: ${g.savedAmount}/${g.targetAmount} (Progress: ${((g.savedAmount/g.targetAmount)*100).toFixed(0)}%)`).join('\n');

    const systemPrompt = `
You are an expert AI Financial Advisor. Your job is to analyze the user's finances and provide exactly 3 items of actionable advice (Insights).

USER DATA:
- Current Month: ${now.toLocaleString('default', { month: 'long', year: 'numeric' })}
- Total Income: ${totalIncome.toFixed(2)} ${user.currency}
- Total Expenses: ${totalExpenses.toFixed(2)} ${user.currency}
- Savings Rate: ${savingsRate.toFixed(0)}%
- Top Spending Categories:
${topCategoriesStr || 'None yet'}
- Budget Status:
${budgetStatusStr || 'No budgets set'}
- Active Savings Goals:
${goalsStr || 'No active goals'}

OUTPUT FORMAT:
You MUST respond with a valid JSON array of exactly 3 objects. No extra text or formatting.
Each object must have these exact keys:
- "type": one of "warning", "tip", "achievement"
- "title": string (max 40 chars)
- "message": string (max 150 chars)
- "icon": single emoji

GUIDELINES:
1. Address GOAL achievement: Tell the user what to increase or decrease to reach their goals.
2. Address ALLOWED/NOT ALLOWED spending: Based on budgets, tell them if they should stop spending in certain categories or if they are doing well ("Allowed").
3. Be specific with numbers where possible.
4. If they have no data, give general smart financial advice.
`;

    const aiResponse = await callAI(systemPrompt, 'Generate my monthly financial insights.');
    
    // Attempt to parse JSON
    try {
      const insights = JSON.parse(aiResponse);
      if (Array.isArray(insights) && insights.length > 0) {
        return insights;
      }
    } catch (e) {
      console.warn('AI Insight parsing failed, falling back to rule-based:', e);
    }

    // Fallback to rule-based insights if AI fails
    return generateRuleBasedInsights(transactions, totalIncome, totalExpenses, savingsRate, goals);
  } catch (error) {
    console.error('Error generating insights:', error);
    return [];
  }
}

function generateRuleBasedInsights(
  transactions: any[],
  totalIncome: number,
  totalExpenses: number,
  savingsRate: number,
  goals: any[]
): Insight[] {
  const insights: Insight[] = [];

  if (savingsRate >= 20) {
    insights.push({
      type: 'achievement',
      title: '🎉 Great Savings Rate!',
      message: `You're saving ${savingsRate.toFixed(0)}% of your income this month. Keep it up!`,
      icon: '🏆',
    });
  } else if (savingsRate < 0) {
    insights.push({
      type: 'warning',
      title: '⚠️ Spending Exceeds Income',
      message: `You've spent more than you've earned this month. Consider reducing expenses.`,
      icon: '🚨',
    });
  }

  // Goal progress
  for (const goal of goals) {
    const progress = (goal.savedAmount / goal.targetAmount) * 100;
    if (progress >= 75) {
      insights.push({
        type: 'achievement',
        title: `🎯 Almost There: ${goal.title}`,
        message: `You've reached ${progress.toFixed(0)}% of your "${goal.title}" goal!`,
        icon: '🎯',
      });
    }
  }

  if (insights.length === 0) {
    insights.push({
      type: 'tip',
      title: '💡 Track your spending',
      message: 'Log your transactions daily to get more accurate AI recommendations.',
      icon: '📝',
    });
  }

  return insights.slice(0, 3);
}
