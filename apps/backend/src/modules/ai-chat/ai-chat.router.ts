import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { aiChatLimiter } from '../../middleware/rateLimit.middleware';
import { validate } from '../../middleware/validate.middleware';
import { sendMessage, getSessions, getSession, deleteSession, simulateTransaction } from './ai-chat.controller';
import { chatMessageSchema, simulateTransactionSchema } from './ai-chat.schema';

export const aiChatRouter: Router = Router();

aiChatRouter.use(requireAuth);

aiChatRouter.post('/chat', aiChatLimiter, validate(chatMessageSchema), sendMessage);
aiChatRouter.post('/simulate', validate(simulateTransactionSchema), simulateTransaction);
aiChatRouter.get('/sessions', getSessions);
aiChatRouter.get('/sessions/:id', getSession);
aiChatRouter.delete('/sessions/:id', deleteSession);
