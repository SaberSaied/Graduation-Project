import { Request, Response, NextFunction } from 'express';
import * as transactionsService from './transactions.service';

export async function getTransactions(req: Request, res: Response, next: NextFunction) {
  try {
    const result = await transactionsService.getTransactions(req.user!.id, req.query as any);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

export async function createTransaction(req: Request, res: Response, next: NextFunction) {
  try {
    const transaction = await transactionsService.createTransaction(req.user!.id, req.body);
    res.status(201).json({ data: transaction, message: 'Transaction created successfully' });
  } catch (error) {
    next(error);
  }
}

export async function getTransaction(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const transaction = await transactionsService.getTransaction(id, req.user!.id);
    res.json({ data: transaction });
  } catch (error) {
    next(error);
  }
}

export async function updateTransaction(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const transaction = await transactionsService.updateTransaction(id, req.user!.id, req.body);
    res.json({ data: transaction, message: 'Transaction updated successfully' });
  } catch (error) {
    next(error);
  }
}

export async function deleteTransaction(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    await transactionsService.deleteTransaction(id, req.user!.id);
    res.json({ message: 'Transaction deleted successfully' });
  } catch (error) {
    next(error);
  }
}

export async function getMonthlySummary(req: Request, res: Response, next: NextFunction) {
  try {
    const month = req.query.month ? parseInt(req.query.month as string) : new Date().getMonth() + 1;
    const year = req.query.year ? parseInt(req.query.year as string) : new Date().getFullYear();
    const summary = await transactionsService.getMonthlySummary(req.user!.id, month, year);
    res.json({ data: summary });
  } catch (error) {
    next(error);
  }
}

export async function getCategoryBreakdown(req: Request, res: Response, next: NextFunction) {
  try {
    const month = req.query.month ? parseInt(req.query.month as string) : new Date().getMonth() + 1;
    const year = req.query.year ? parseInt(req.query.year as string) : new Date().getFullYear();
    const type = (req.query.type as string) || 'EXPENSE';
    const breakdown = await transactionsService.getCategoryBreakdown(req.user!.id, month, year, type);
    res.json({ data: breakdown });
  } catch (error) {
    next(error);
  }
}
