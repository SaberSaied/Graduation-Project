import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validate.middleware';
import { getBudgets, createBudget, updateBudget, deleteBudget, getBudgetStatus, getAnalytics } from './budgets.controller';
import { createBudgetSchema, updateBudgetSchema } from './budgets.schema';

export const budgetsRouter: Router = Router();

budgetsRouter.use(requireAuth);

budgetsRouter.get('/', getBudgets);
budgetsRouter.post('/', validate(createBudgetSchema), createBudget);
budgetsRouter.get('/status', getBudgetStatus);
budgetsRouter.get('/analytics', getAnalytics);
budgetsRouter.patch('/:id', validate(updateBudgetSchema), updateBudget);
budgetsRouter.delete('/:id', deleteBudget);
