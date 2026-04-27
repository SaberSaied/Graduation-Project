import { Request, Response, NextFunction } from 'express';
import * as analyticsService from './analytics.service';
import { generateInsights } from '../../services/insights.service';

export async function getDashboard(req: Request, res: Response, next: NextFunction) {
  try {
    const dashboard = await analyticsService.getDashboardData(req.user!.id);
    res.json({ data: dashboard });
  } catch (error) {
    next(error);
  }
}

export async function getMonthlyReport(req: Request, res: Response, next: NextFunction) {
  try {
    const month = req.query.month ? parseInt(req.query.month as string) : new Date().getMonth() + 1;
    const year = req.query.year ? parseInt(req.query.year as string) : new Date().getFullYear();
    const report = await analyticsService.getMonthlyReport(req.user!.id, month, year);
    res.json({ data: report });
  } catch (error) {
    next(error);
  }
}

export async function getTrends(req: Request, res: Response, next: NextFunction) {
  try {
    const months = req.query.months ? parseInt(req.query.months as string) : 6;
    const trends = await analyticsService.getSpendingTrends(req.user!.id, months);
    res.json({ data: trends });
  } catch (error) {
    next(error);
  }
}

export async function getTopCategories(req: Request, res: Response, next: NextFunction) {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 5;
    const categories = await analyticsService.getTopSpendingCategories(req.user!.id, limit);
    res.json({ data: categories });
  } catch (error) {
    next(error);
  }
}

export async function getInsights(req: Request, res: Response, next: NextFunction) {
  try {
    const insights = await generateInsights(req.user!.id);
    res.json({ data: insights });
  } catch (error) {
    next(error);
  }
}
