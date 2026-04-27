import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';

export async function getCategories(userId: string) {
  return prisma.category.findMany({
    where: {
      OR: [
        { isDefault: true },
        { userId },
      ],
    },
    orderBy: [{ isDefault: 'desc' }, { name: 'asc' }],
  });
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

export async function updateCategory(categoryId: string, userId: string, data: { name?: string; icon?: string; color?: string }) {
  const category = await prisma.category.findUnique({ where: { id: categoryId } });

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  if (category.isDefault) {
    throw new AppError('Cannot modify default categories', 403);
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
