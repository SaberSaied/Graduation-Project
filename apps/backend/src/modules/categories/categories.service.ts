import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';
import { DEFAULT_EXPENSE_CATEGORIES, DEFAULT_INCOME_CATEGORIES } from './categories.constants';

export async function createDefaultCategories(userId: string) {
  // Check if user already has categories to prevent duplicates
  const existingCount = await prisma.category.count({ where: { userId } });
  if (existingCount > 0) return;

  const expenseData = DEFAULT_EXPENSE_CATEGORIES.map(cat => ({
    ...cat,
    type: 'EXPENSE' as const,
    userId,
    isDefault: true, // Marking them as default for this user
  }));

  const incomeData = DEFAULT_INCOME_CATEGORIES.map(cat => ({
    ...cat,
    type: 'INCOME' as const,
    userId,
    isDefault: true,
  }));

  return prisma.$transaction(
    [...expenseData, ...incomeData].map(data =>
      prisma.category.create({ data })
    )
  );
}

export async function getCategories(userId: string, filters?: { type?: 'INCOME' | 'EXPENSE', search?: string }) {
  const categories = await prisma.category.findMany({
    where: {
      userId,
      AND: [
        filters?.type ? { type: filters.type } : {},
        filters?.search ? { name: { contains: filters.search, mode: 'insensitive' } } : {},
      ],
    },
    orderBy: { name: 'asc' },
  });

  const incomeCategories = categories.filter(c => c.type === 'INCOME');
  const expenseCategories = categories.filter(c => c.type === 'EXPENSE');

  return {
    incomeCategories,
    expenseCategories,
    all: categories,
  };
}

export async function createCategory(userId: string, data: { name: string; icon: string; color: string; type: 'INCOME' | 'EXPENSE' }) {
  return prisma.category.create({
    data: {
      ...data,
      userId,
      isDefault: false,
    },
  });
}

export async function updateCategory(categoryId: string, userId: string, data: { name?: string; icon?: string; color?: string; type?: 'INCOME' | 'EXPENSE' }) {
  const category = await prisma.category.findUnique({ where: { id: categoryId } });

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  if (category.isDefault) {
    // Create a new user-specific category instead of updating the global default
    return prisma.category.create({
      data: {
        name: data.name ?? category.name,
        icon: data.icon ?? category.icon,
        color: data.color ?? category.color,
        type: (data.type ?? category.type) as any,
        userId,
        isDefault: false,
      },
    });
  }

  if (category.userId !== userId) {
    throw new AppError('Not authorized to modify this category', 403);
  }

  return prisma.category.update({
    where: { id: categoryId },
    data,
  });
}

export async function deleteCategory(categoryId: string, userId: string) {
  const category = await prisma.category.findUnique({ where: { id: categoryId } });

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  if (category.isDefault) {
    throw new AppError('Cannot delete default categories', 403);
  }

  if (category.userId !== userId) {
    throw new AppError('Not authorized to delete this category', 403);
  }

  // Check if category is in use
  const transactionCount = await prisma.transaction.count({ where: { categoryId } });
  if (transactionCount > 0) {
    throw new AppError('Cannot delete category with existing transactions. Delete or reassign transactions first.', 400);
  }

  return prisma.category.delete({ where: { id: categoryId } });
}
