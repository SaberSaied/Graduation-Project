import { Request, Response, NextFunction } from 'express';
import * as budgetsService from './budgets.service';

export async function getBudgets(req: Request, res: Response, next: NextFunction) {
  try {
    const month = req.query.month ? parseInt(req.query.month as string) : new Date().getMonth() + 1;
    const year = req.query.year ? parseInt(req.query.year as string) : new Date().getFullYear();
    const budgets = await budgetsService.getBudgets(req.user!.id, month, year);
    res.json({ data: budgets });
  } catch (error) {
    next(error);
  }
}

export async function createBudget(req: Request, res: Response, next: NextFunction) {
  try {
    const budget = await budgetsService.createBudget(req.user!.id, req.body);
    res.status(201).json({ data: budget, message: 'Budget created successfully' });
  } catch (error) {
    next(error);
  }
}

export async function updateBudget(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const budget = await budgetsService.updateBudget(id, req.user!.id, req.body);
    res.json({ data: budget, message: 'Budget updated successfully' });
  } catch (error) {
    next(error);
  }
}

export async function deleteBudget(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    await budgetsService.deleteBudget(id, req.user!.id);
    res.json({ message: 'Budget deleted successfully' });
  } catch (error) {
    next(error);
  }
}

export async function getBudgetStatus(req: Request, res: Response, next: NextFunction) {
  try {
    const month = req.query.month ? parseInt(req.query.month as string) : new Date().getMonth() + 1;
    const year = req.query.year ? parseInt(req.query.year as string) : new Date().getFullYear();
    const status = await budgetsService.getBudgetStatus(req.user!.id, month, year);
    res.json({ data: status });
  } catch (error) {
    next(error);
  }
}
