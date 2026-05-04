import { z } from 'zod';

export const chatMessageSchema = z.object({
  message: z.string().min(1).max(2000, 'Message too long (max 2000 characters)'),
  sessionId: z.string().optional().nullable(),
});

export const simulateTransactionSchema = z.object({
  amount: z.number().positive(),
  categoryId: z.string(),
  goalId: z.string().optional().nullable(),
});
