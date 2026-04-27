import { z } from 'zod';

export const createBudgetSchema = z.object({
  categoryId: z.string().min(1),
  amount: z.number().positive('Budget amount must be positive'),
  currency: z.string().length(3).default('USD'),
  month: z.number().int().min(1).max(12),
  year: z.number().int().min(2020).max(2100),
});

export const updateBudgetSchema = z.object({
  amount: z.number().positive('Budget amount must be positive').optional(),
});
