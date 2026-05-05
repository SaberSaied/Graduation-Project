import { Router } from 'express';
import multer from 'multer';
import { requireAuth } from '../../middleware/auth.middleware';
import { aiChatLimiter } from '../../middleware/rateLimit.middleware';
import { validate } from '../../middleware/validate.middleware';
import { sendMessage, getSessions, getSession, deleteSession, simulateTransaction } from './ai-chat.controller';
import { chatMessageSchema, simulateTransactionSchema } from './ai-chat.schema';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
});

export const aiChatRouter: Router = Router();

aiChatRouter.use(requireAuth);

aiChatRouter.post('/chat', upload.single('file'), aiChatLimiter, sendMessage);
aiChatRouter.post('/simulate', validate(simulateTransactionSchema), simulateTransaction);
aiChatRouter.get('/sessions', getSessions);
aiChatRouter.get('/sessions/:id', getSession);
aiChatRouter.delete('/sessions/:id', deleteSession);
