import { z } from 'zod';

export const createGoalSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(1000).optional().nullable(),
  targetAmount: z.number().positive('Target amount must be positive'),
  currency: z.string().length(3).default('USD'),
  deadline: z.string().datetime().optional().nullable(),
  icon: z.string().max(10).optional().nullable(),
  color: z.string().max(7).optional().nullable(),
  autoSaveAmount: z.number().nonnegative().optional(),
  autoSavePercentage: z.number().min(0).max(100).optional(),
  autoSaveFrequency: z.enum(['DAILY', 'WEEKLY', 'MONTHLY']).optional(),
});

export const updateGoalSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(1000).optional().nullable(),
  targetAmount: z.number().positive().optional(),
  deadline: z.string().datetime().optional().nullable(),
  icon: z.string().max(10).optional().nullable(),
  color: z.string().max(7).optional().nullable(),
  status: z.enum(['IN_PROGRESS', 'COMPLETED', 'CANCELLED']).optional(),
  autoSaveAmount: z.number().nonnegative().optional(),
  autoSavePercentage: z.number().min(0).max(100).optional(),
  autoSaveFrequency: z.enum(['DAILY', 'WEEKLY', 'MONTHLY']).optional(),
});

export const contributeSchema = z.object({
  amount: z.number().positive('Contribution must be positive'),
  note: z.string().max(500).optional().nullable(),
  transactionId: z.string().optional(),
});
