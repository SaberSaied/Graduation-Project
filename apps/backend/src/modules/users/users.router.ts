import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validate.middleware';
import { getMe, updateMe, deleteMe, getFinancialSummary } from './users.controller';
import { updateUserSchema } from './users.schema';

export const usersRouter: Router = Router();

// All user routes require authentication
usersRouter.use(requireAuth);

usersRouter.get('/me', getMe);
usersRouter.patch('/me', validate(updateUserSchema), updateMe);
usersRouter.delete('/me', deleteMe);
usersRouter.get('/me/summary', getFinancialSummary);
