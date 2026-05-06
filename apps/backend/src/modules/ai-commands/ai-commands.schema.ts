import { z } from 'zod';

export const AIActionTypeSchema = z.enum([
  'CREATE_CATEGORY',
  'CREATE_TRANSACTION',
  'CREATE_BUDGET',
  'CREATE_GOAL',
  'CONTRIBUTE_TO_GOAL',
  'CREATE_REMINDER',
  'CREATE_NOTE',
]);

export const AIActionSchema = z.object({
  type: AIActionTypeSchema,
  data: z.any(),
});

export const AICommandResponseSchema = z.object({
  actions: z.array(AIActionSchema),
  summary: z.string(),
});

export type AIActionType = z.infer<typeof AIActionTypeSchema>;
export type AIAction = z.infer<typeof AIActionSchema>;
export type AICommandResponse = z.infer<typeof AICommandResponseSchema>;

export const ProcessCommandSchema = z.object({
  prompt: z.string().min(1),
});

export const ExecuteCommandsSchema = z.object({
  actions: z.array(AIActionSchema),
});
