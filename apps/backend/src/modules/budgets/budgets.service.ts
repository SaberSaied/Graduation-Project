import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';
import { BudgetStatus } from '../../types/api.types';

export async function getBudgets(userId: string, month: number, year: number) {
  return prisma.budget.findMany({
    where: { userId, month, year },
    include: { category: true },
    orderBy: { category: { name: 'asc' } },
  });
}

export async function createBudget(
  userId: string,
  data: { categoryId: string; amount: number; currency: string; month: number; year: number }
) {
  return prisma.budget.create({
    data: { userId, ...data },
    include: { category: true },
  });
}

export async function updateBudget(budgetId: string, userId: string, data: { amount?: number }) {
  const budget = await prisma.budget.findFirst({ where: { id: budgetId, userId } });
  if (!budget) throw new AppError('Budget not found', 404);

  return prisma.budget.update({
    where: { id: budgetId },
    data,
    include: { category: true },
  });
}

export async function deleteBudget(budgetId: string, userId: string) {
  const budget = await prisma.budget.findFirst({ where: { id: budgetId, userId } });
  if (!budget) throw new AppError('Budget not found', 404);

  return prisma.budget.delete({ where: { id: budgetId } });
}

export async function getBudgetStatus(userId: string, month: number, year: number): Promise<BudgetStatus[]> {
  const budgets = await prisma.budget.findMany({
    where: { userId, month, year },
    include: { category: true },
  });

  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 1);

  const statuses: BudgetStatus[] = [];

  for (const budget of budgets) {
    const spent = await prisma.transaction.aggregate({
      where: {
        userId,
        categoryId: budget.categoryId,
        type: 'EXPENSE',
        date: { gte: startDate, lt: endDate },
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
