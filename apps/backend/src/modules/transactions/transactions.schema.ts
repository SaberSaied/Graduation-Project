import { z } from 'zod';

export const createTransactionSchema = z.object({
  categoryId: z.string().min(1),
  type: z.enum(['INCOME', 'EXPENSE']),
  amount: z.number().positive('Amount must be positive'),
  currency: z.string().length(3).default('USD'),
  title: z.string().min(1).max(200),
  notes: z.string().max(1000).optional().nullable(),
  date: z.string().transform((s) => new Date(s)),
  isRecurring: z.boolean().default(false),
  recurringInterval: z.enum(['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY']).optional().nullable(),
  goalId: z.string().optional().nullable(),
});

export const updateTransactionSchema = z.object({
  categoryId: z.string().min(1).optional(),
  type: z.enum(['INCOME', 'EXPENSE']).optional(),
  amount: z.number().positive().optional(),
  currency: z.string().length(3).optional(),
  title: z.string().min(1).max(200).optional(),
  notes: z.string().max(1000).optional().nullable(),
  date: z.string().transform((s) => new Date(s)).optional(),
  isRecurring: z.boolean().optional(),
  recurringInterval: z.enum(['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY']).optional().nullable(),
});

export const transactionQuerySchema = z.object({
  type: z.enum(['INCOME', 'EXPENSE']).optional(),
  from: z.string().optional(),
  to: z.string().optional(),
  categoryId: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});
