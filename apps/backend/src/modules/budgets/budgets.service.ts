import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';
import { BudgetStatus } from '../../types/api.types';
import { 
  startOfMonth, 
  endOfMonth, 
  startOfWeek, 
  endOfWeek, 
  isWithinInterval,
  subMonths
} from 'date-fns';

export async function getBudgets(userId: string) {
  return prisma.budget.findMany({
    where: { userId },
    include: { category: true },
    orderBy: { category: { name: 'asc' } },
  });
}

export async function createBudget(
  userId: string,
  data: { 
    categoryId: string; 
    amount: number; 
    currency: string; 
    period: 'WEEKLY' | 'MONTHLY' | 'CUSTOM';
    startDate?: string;
    endDate?: string;
    month?: number;
    year?: number;
    alertThreshold?: number;
  }
) {
  const { startDate, endDate, ...rest } = data;
  return prisma.budget.create({
    data: { 
      userId, 
      ...rest,
      startDate: startDate ? new Date(startDate) : null,
      endDate: endDate ? new Date(endDate) : null,
    } as any,
    include: { category: true },
  });
}

export async function updateBudget(
  budgetId: string, 
  userId: string, 
  data: Partial<{ 
    amount: number;
    period: 'WEEKLY' | 'MONTHLY' | 'CUSTOM';
    startDate: string;
    endDate: string;
    month: number;
    year: number;
    alertThreshold: number;
  }>
) {
  const { startDate, endDate, ...rest } = data;
  const updateData: any = { ...rest };
  if (startDate) updateData.startDate = new Date(startDate);
  if (endDate) updateData.endDate = new Date(endDate);

  return prisma.budget.update({
    where: { id: budgetId },
    data: updateData,
    include: { category: true },
  });
}

export async function deleteBudget(budgetId: string, userId: string) {
  const budget = await prisma.budget.findFirst({ where: { id: budgetId, userId } });
  if (!budget) throw new AppError('Budget not found', 404);

  return prisma.budget.delete({ where: { id: budgetId } });
}

export async function getBudgetStatus(userId: string): Promise<BudgetStatus[]> {
  const budgets = await prisma.budget.findMany({
    where: { userId },
    include: { category: true },
  }) as any;

  const now = new Date();
  const statuses: BudgetStatus[] = [];

  for (const budget of budgets) {
    let startDate: Date;
    let endDate: Date;

    if (budget.period === 'WEEKLY') {
      startDate = startOfWeek(now);
      endDate = endOfWeek(now);
    } else if (budget.period === 'MONTHLY') {
      startDate = startOfMonth(now);
      endDate = endOfMonth(now);
    } else {
      startDate = budget.startDate || startOfMonth(now);
      endDate = budget.endDate || endOfMonth(now);
    }

    const spent = await prisma.transaction.aggregate({
      where: {
        userId,
        categoryId: budget.categoryId,
        type: 'EXPENSE',
        date: { gte: startDate, lte: endDate },
      },
      _sum: { amountInBaseCurrency: true },
    });

    const totalSpent = spent._sum.amountInBaseCurrency ?? 0;

    statuses.push({
      budgetId: budget.id,
      category: budget.category.name,
      categoryIcon: budget.category.icon,
      limit: budget.amount,
      spent: Math.round(totalSpent * 100) / 100,
      remaining: Math.round((budget.amount - totalSpent) * 100) / 100,
      usagePercent: Math.round((totalSpent / budget.amount) * 100),
    });
  }

  return statuses.sort((a, b) => b.usagePercent - a.usagePercent);
}

export async function getBudgetAnalytics(userId: string) {
  const now = new Date();
  const last3Months = subMonths(now, 3);

  // Get total spending per category in last 3 months
  const spending = await prisma.transaction.groupBy({
    by: ['categoryId'],
    where: {
      userId,
      type: 'EXPENSE',
      date: { gte: last3Months },
    },
    _sum: { amountInBaseCurrency: true },
  });

  const categories = await prisma.category.findMany({
    where: { id: { in: spending.map(s => s.categoryId) } }
  });

  const topCategories = spending.map(s => {
    const category = categories.find(c => c.id === s.categoryId);
    return {
      name: category?.name || 'Unknown',
      amount: s._sum.amountInBaseCurrency || 0,
    };
  }).sort((a, b) => b.amount - a.amount).slice(0, 5);

  return {
    topCategories,
    period: 'last_3_months',
  };
}
