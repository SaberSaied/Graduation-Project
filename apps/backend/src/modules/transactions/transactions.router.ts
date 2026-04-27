import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validate.middleware';
import {
  getTransactions,
  createTransaction,
  getTransaction,
  updateTransaction,
  deleteTransaction,
  getMonthlySummary,
  getCategoryBreakdown,
} from './transactions.controller';
import { createTransactionSchema, updateTransactionSchema, transactionQuerySchema } from './transactions.schema';

export const transactionsRouter: Router = Router();

transactionsRouter.use(requireAuth);

transactionsRouter.get('/', validate(transactionQuerySchema, 'query'), getTransactions);
transactionsRouter.post('/', validate(createTransactionSchema), createTransaction);
transactionsRouter.get('/summary/monthly', getMonthlySummary);
transactionsRouter.get('/summary/by-category', getCategoryBreakdown);
transactionsRouter.get('/:id', getTransaction);
transactionsRouter.patch('/:id', validate(updateTransactionSchema), updateTransaction);
transactionsRouter.delete('/:id', deleteTransaction);
