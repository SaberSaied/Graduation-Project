import { prisma } from '../../config/database';
import { convertAmount } from '../../services/currency.service';
import { AppError } from '../../middleware/error.middleware';
import { PaginatedResponse, MonthlySummary, CategoryBreakdown } from '../../types/api.types';

interface TransactionQuery {
  type?: 'INCOME' | 'EXPENSE';
  from?: string;
  to?: string;
  categoryId?: string;
  page: number;
  limit: number;
}

export async function getTransactions(userId: string, query: TransactionQuery): Promise<PaginatedResponse> {
  const { type, from, to, categoryId, page, limit } = query;

  const where: any = { userId };
  if (type) where.type = type;
  if (categoryId) where.categoryId = categoryId;
  if (from || to) {
    where.date = {};
    if (from) where.date.gte = new Date(from);
    if (to) where.date.lte = new Date(to);
  }

  const [transactions, totalCount] = await Promise.all([
    prisma.transaction.findMany({
      where,
      include: { category: true },
      orderBy: { date: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.transaction.count({ where }),
  ]);

  const totalPages = Math.ceil(totalCount / limit);

  return {
    data: transactions,
    pagination: {
      page,
      limit,
      totalCount,
      totalPages,
      hasNext: page < totalPages,
      hasPrevious: page > 1,
    },
  };
}

export async function createTransaction(
  userId: string,
  data: {
    categoryId: string;
    type: 'INCOME' | 'EXPENSE';
    amount: number;
    currency: string;
    title: string;
    notes?: string | null;
    date: Date;
    isRecurring?: boolean;
    recurringInterval?: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY' | null;
    goalId?: string | null;
  }
) {
  // Get user's base currency
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });

  // Convert to base currency
  const { convertedAmount, exchangeRate } = await convertAmount(
    data.amount,
    data.currency,
    user.currency
  );

  const transaction = await prisma.transaction.create({
    data: {
      userId,
      categoryId: data.categoryId,
      type: data.type,
      amount: data.amount,
      currency: data.currency,
      amountInBaseCurrency: convertedAmount,
      exchangeRate,
      title: data.title,
      notes: data.notes,
      date: data.date,
      isRecurring: data.isRecurring ?? false,
      recurringInterval: data.recurringInterval,
    },
    include: { category: true },
  });

  // Check budget alerts after creating expense
  if (data.type === 'EXPENSE') {
    await checkBudgetAlert(userId, data.categoryId);
  }

  if (data.goalId) {
    const goal = await prisma.goal.findUnique({ where: { id: data.goalId } });
    if (goal && goal.userId === userId) {
      if (data.type === 'INCOME') {
        await prisma.goal.update({
          where: { id: goal.id },
          data: { savedAmount: goal.savedAmount + convertedAmount }
        });
        await prisma.goalContribution.create({
          data: { goalId: goal.id, amount: convertedAmount, note: `Income: ${data.title}` }
        });
      } else if (data.type === 'EXPENSE') {
        const newAmount = Math.max(0, goal.savedAmount - convertedAmount);
        await prisma.goal.update({
          where: { id: goal.id },
          data: { savedAmount: newAmount, status: 'IN_PROGRESS' }
        });
        await prisma.goalContribution.create({
          data: { goalId: goal.id, amount: -convertedAmount, note: `Expense: ${data.title}` }
        });
      }
    }
  }

  // Handle Budget increment on INCOME
  if (data.type === 'INCOME') {
    const d = new Date(data.date);
    const month = d.getMonth() + 1;
    const year = d.getFullYear();

    const budget = await prisma.budget.findUnique({
      where: {
        userId_categoryId_month_year: { userId, categoryId: data.categoryId, month, year },
      },
    });

    if (budget) {
      await prisma.budget.update({
        where: { id: budget.id },
        data: { amount: budget.amount + convertedAmount },
      });
    } else {
      await prisma.budget.create({
        data: {
          userId,
          categoryId: data.categoryId,
          month,
          year,
          amount: convertedAmount,
          currency: user.currency,
        },
      });
    }
  }

  return transaction;
}

export async function getTransaction(transactionId: string, userId: string) {
  const transaction = await prisma.transaction.findFirst({
    where: { id: transactionId, userId },
    include: { category: true },
  });

  if (!transaction) {
    throw new AppError('Transaction not found', 404);
  }

  return transaction;
}

export async function updateTransaction(
  transactionId: string,
  userId: string,
  data: Partial<{
    categoryId: string;
    type: 'INCOME' | 'EXPENSE';
    amount: number;
    currency: string;
    title: string;
    notes: string | null;
    date: Date;
    isRecurring: boolean;
    recurringInterval: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY' | null;
  }>
) {
  const existing = await prisma.transaction.findFirst({
    where: { id: transactionId, userId },
  });

  if (!existing) {
    throw new AppError('Transaction not found', 404);
  }

  let updateData: any = { ...data };

  // Recalculate converted amount if amount or currency changed
  if (data.amount || data.currency) {
    const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
    const amount = data.amount ?? existing.amount;
    const currency = data.currency ?? existing.currency;
    const { convertedAmount, exchangeRate } = await convertAmount(amount, currency, user.currency);
    updateData.amountInBaseCurrency = convertedAmount;
    updateData.exchangeRate = exchangeRate;
  }

  return prisma.transaction.update({
    where: { id: transactionId },
    data: updateData,
    include: { category: true },
  });
}

export async function deleteTransaction(transactionId: string, userId: string) {
  const transaction = await prisma.transaction.findFirst({
    where: { id: transactionId, userId },
  });

  if (!transaction) {
    throw new AppError('Transaction not found', 404);
  }

  return prisma.transaction.delete({ where: { id: transactionId } });
}

export async function getMonthlySummary(userId: string, month: number, year: number): Promise<MonthlySummary> {
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 1);

  const transactions = await prisma.transaction.findMany({
    where: {
      userId,
      date: { gte: startDate, lt: endDate },
    },
  });

  const totalIncome = transactions
    .filter((t) => t.type === 'INCOME')
    .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  const totalExpenses = transactions
    .filter((t) => t.type === 'EXPENSE')
    .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  return {
    totalIncome: Math.round(totalIncome * 100) / 100,
    totalExpenses: Math.round(totalExpenses * 100) / 100,
    netBalance: Math.round((totalIncome - totalExpenses) * 100) / 100,
    savingsRate: totalIncome > 0 ? Math.round(((totalIncome - totalExpenses) / totalIncome) * 100) : 0,
    transactionCount: transactions.length,
  };
}

export async function getCategoryBreakdown(
  userId: string,
  month: number,
  year: number,
  type: string
): Promise<CategoryBreakdown[]> {
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 1);

  const transactions = await prisma.transaction.findMany({
    where: {
      userId,
      type: type as any,
      date: { gte: startDate, lt: endDate },
    },
    include: { category: true },
  });

  const categoryMap = new Map<string, CategoryBreakdown>();
  let grandTotal = 0;

  for (const t of transactions) {
    grandTotal += t.amountInBaseCurrency;
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
  }

  const result = [...categoryMap.values()]
    .map((c) => ({
      ...c,
      total: Math.round(c.total * 100) / 100,
      percentage: grandTotal > 0 ? Math.round((c.total / grandTotal) * 100) : 0,
    }))
    .sort((a, b) => b.total - a.total);

  return result;
}

// Helper: Check budget and create notification if needed
async function checkBudgetAlert(userId: string, categoryId: string) {
  const now = new Date();
  const month = now.getMonth() + 1;
  const year = now.getFullYear();

  const budget = await prisma.budget.findUnique({
    where: {
      userId_categoryId_month_year: { userId, categoryId, month, year },
    },
    include: { category: true },
  });

  if (!budget) return;

  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 1);

  const spent = await prisma.transaction.aggregate({
    where: {
      userId,
      categoryId,
      type: 'EXPENSE',
      date: { gte: startDate, lt: endDate },
    },
    _sum: { amountInBaseCurrency: true },
  });

  const totalSpent = spent._sum.amountInBaseCurrency ?? 0;
  const usagePercent = (totalSpent / budget.amount) * 100;

  if (usagePercent >= 100) {
    await prisma.notification.create({
      data: {
        userId,
        type: 'OVERSPEND_WARNING',
        title: '🚨 Budget Exceeded',
        message: `You've exceeded your ${budget.category.name} budget by ${(totalSpent - budget.amount).toFixed(2)}.`,
        metadata: { budgetId: budget.id, categoryId, usagePercent },
      },
    });
  } else if (usagePercent >= 80) {
    await prisma.notification.create({
      data: {
        userId,
        type: 'BUDGET_ALERT',
        title: '⚠️ Budget Alert',
        message: `You've used ${usagePercent.toFixed(0)}% of your ${budget.category.name} budget.`,
        metadata: { budgetId: budget.id, categoryId, usagePercent },
      },
    });
  }
}
