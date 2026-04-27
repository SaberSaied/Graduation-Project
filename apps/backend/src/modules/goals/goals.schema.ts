import { z } from 'zod';

export const createGoalSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(1000).optional().nullable(),
  targetAmount: z.number().positive('Target amount must be positive'),
  currency: z.string().length(3).default('USD'),
  deadline: z.string().transform((s) => new Date(s)).optional().nullable(),
  icon: z.string().max(10).optional().nullable(),
  color: z.string().max(7).optional().nullable(),
});

export const updateGoalSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(1000).optional().nullable(),
  targetAmount: z.number().positive().optional(),
  deadline: z.string().transform((s) => new Date(s)).optional().nullable(),
  icon: z.string().max(10).optional().nullable(),
  color: z.string().max(7).optional().nullable(),
  status: z.enum(['IN_PROGRESS', 'COMPLETED', 'CANCELLED']).optional(),
});

export const contributeSchema = z.object({
  amount: z.number().positive('Contribution must be positive'),
  note: z.string().max(500).optional().nullable(),
});
