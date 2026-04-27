import { prisma } from '../../config/database';
import { DashboardData, CategoryBreakdown } from '../../types/api.types';

export async function getDashboardData(userId: string): Promise<DashboardData> {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  const [user, transactions, recentTx, budgets, goals] = await Promise.all([
    prisma.user.findUniqueOrThrow({ where: { id: userId } }),
    prisma.transaction.findMany({
      where: { userId, date: { gte: startOfMonth, lt: endOfMonth } },
      include: { category: true },
    }),
    prisma.transaction.findMany({
      where: { userId },
      include: { category: true },
      orderBy: { date: 'desc' },
      take: 5,
    }),
    prisma.budget.findMany({
      where: { userId, month: now.getMonth() + 1, year: now.getFullYear() },
      include: { category: true },
    }),
    prisma.goal.findMany({
      where: { userId, status: 'IN_PROGRESS' },
      orderBy: { createdAt: 'desc' },
      take: 3,
    }),
  ]);

  const totalIncome = transactions
    .filter((t) => t.type === 'INCOME')
    .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  const totalExpenses = transactions
    .filter((t) => t.type === 'EXPENSE')
    .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  // Category breakdown
  const categoryMap = new Map<string, CategoryBreakdown>();
  transactions
    .filter((t) => t.type === 'EXPENSE')
    .forEach((t) => {
      const existing = categoryMap.get(t.categoryId);
      if (existing) {
        existing.total += t.amountInBaseCurrency;
        existing.count += 1;
      } else {
        categoryMap.set(t.categoryId, {
          categoryId: t.categoryId,
          name: t.category.name,
          icon: t.category.icon,
          color: t.category.color,
          total: t.amountInBaseCurrency,
          percentage: 0,
          count: 1,
        });
      }
    });

  const categoryBreakdown = [...categoryMap.values()]
    .map((c) => ({
      ...c,
      total: Math.round(c.total * 100) / 100,
      percentage: totalExpenses > 0 ? Math.round((c.total / totalExpenses) * 100) : 0,
    }))
    .sort((a, b) => b.total - a.total);

  // Budget alerts
  const budgetAlerts = [];
  for (const budget of budgets) {
    const spent = transactions
      .filter((t) => t.type === 'EXPENSE' && t.categoryId === budget.categoryId)
      .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

    const usagePercent = Math.round((spent / budget.amount) * 100);
    if (usagePercent >= 70) {
      budgetAlerts.push({
        budgetId: budget.id,
        category: budget.category.name,
        categoryIcon: budget.category.icon,
        limit: budget.amount,
        spent: Math.round(spent * 100) / 100,
        remaining: Math.round((budget.amount - spent) * 100) / 100,
        usagePercent,
      });
    }
  }

  return {
    balance: Math.round((totalIncome - totalExpenses) * 100) / 100,
    totalIncome: Math.round(totalIncome * 100) / 100,
    totalExpenses: Math.round(totalExpenses * 100) / 100,
    savingsRate: totalIncome > 0 ? Math.round(((totalIncome - totalExpenses) / totalIncome) * 100) : 0,
    recentTransactions: recentTx,
    categoryBreakdown,
    budgetAlerts,
    activeGoals: goals,
  };
}

export async function getMonthlyReport(userId: string, month: number, year: number) {
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 1);

  const transactions = await prisma.transaction.findMany({
    where: { userId, date: { gte: startDate, lt: endDate } },
    include: { category: true },
    orderBy: { date: 'desc' },
  });

  const income = transactions.filter((t) => t.type === 'INCOME');
  const expenses = transactions.filter((t) => t.type === 'EXPENSE');

  const totalIncome = income.reduce((sum, t) => sum + t.amountInBaseCurrency, 0);
  const totalExpenses = expenses.reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  // Daily spending breakdown
  const dailySpending = new Map<string, number>();
  expenses.forEach((t) => {
    const day = t.date.toISOString().split('T')[0];
    dailySpending.set(day, (dailySpending.get(day) ?? 0) + t.amountInBaseCurrency);
  });

  return {
    month,
    year,
    totalIncome: Math.round(totalIncome * 100) / 100,
    totalExpenses: Math.round(totalExpenses * 100) / 100,
    netBalance: Math.round((totalIncome - totalExpenses) * 100) / 100,
    savingsRate: totalIncome > 0 ? Math.round(((totalIncome - totalExpenses) / totalIncome) * 100) : 0,
    transactionCount: transactions.length,
    incomeCount: income.length,
    expenseCount: expenses.length,
    averageDailySpend: expenses.length > 0
      ? Math.round((totalExpenses / new Date(year, month, 0).getDate()) * 100) / 100
      : 0,
    dailySpending: Object.fromEntries(dailySpending),
    transactions,
  };
}

export async function getSpendingTrends(userId: string, months: number) {
  const trends = [];
  const now = new Date();

  for (let i = months - 1; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const startDate = new Date(date.getFullYear(), date.getMonth(), 1);
    const endDate = new Date(date.getFullYear(), date.getMonth() + 1, 1);

    const transactions = await prisma.transaction.findMany({
      where: { userId, date: { gte: startDate, lt: endDate } },
    });

    const income = transactions
      .filter((t) => t.type === 'INCOME')
      .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

    const expenses = transactions
      .filter((t) => t.type === 'EXPENSE')
      .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

    trends.push({
      month: date.getMonth() + 1,
      year: date.getFullYear(),
      label: date.toLocaleString('default', { month: 'short', year: 'numeric' }),
      income: Math.round(income * 100) / 100,
      expenses: Math.round(expenses * 100) / 100,
      net: Math.round((income - expenses) * 100) / 100,
    });
  }

  return trends;
}

export async function getTopSpendingCategories(userId: string, limit: number) {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  const transactions = await prisma.transaction.findMany({
    where: {
      userId,
      type: 'EXPENSE',
      date: { gte: startOfMonth, lt: endOfMonth },
    },
    include: { category: true },
  });

  const categoryMap = new Map<string, { name: string; icon: string; color: string; total: number; count: number }>();
  let grandTotal = 0;

  for (const t of transactions) {
    grandTotal += t.amountInBaseCurrency;
    const existing = categoryMap.get(t.categoryId);
    if (existing) {
      existing.total += t.amountInBaseCurrency;
      existing.count += 1;
    } else {
      categoryMap.set(t.categoryId, {
        name: t.category.name,
        icon: t.category.icon,
        color: t.category.color,
        total: t.amountInBaseCurrency,
        count: 1,
      });
    }
  }

  return [...categoryMap.values()]
    .map((c) => ({
      ...c,
      total: Math.round(c.total * 100) / 100,
      percentage: grandTotal > 0 ? Math.round((c.total / grandTotal) * 100) : 0,
    }))
    .sort((a, b) => b.total - a.total)
    .slice(0, limit);
}
