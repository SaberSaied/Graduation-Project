import { z } from 'zod';

export const createBudgetSchema = z.object({
  categoryId: z.string().min(1),
  amount: z.number().positive('Budget amount must be positive'),
  currency: z.string().length(3).default('USD'),
  period: z.enum(['WEEKLY', 'MONTHLY', 'CUSTOM']).default('MONTHLY'),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  alertThreshold: z.number().min(0).max(1).default(0.8),
});

export const updateBudgetSchema = z.object({
  amount: z.number().positive('Budget amount must be positive').optional(),
  period: z.enum(['WEEKLY', 'MONTHLY', 'CUSTOM']).optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  alertThreshold: z.number().min(0).max(1).optional(),
});
