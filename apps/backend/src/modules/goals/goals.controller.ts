import { Request, Response, NextFunction } from 'express';
import * as goalsService from './goals.service';

export async function getGoals(req: Request, res: Response, next: NextFunction) {
  try {
    const goals = await goalsService.getGoals(req.user!.id);
    res.json({ data: goals });
  } catch (error) {
    next(error);
  }
}

export async function getGoal(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const goal = await goalsService.getGoal(id, req.user!.id);
    res.json({ data: goal });
  } catch (error) {
    next(error);
  }
}

export async function createGoal(req: Request, res: Response, next: NextFunction) {
  try {
    const goal = await goalsService.createGoal(req.user!.id, req.body);
    res.status(201).json({ data: goal, message: 'Goal created successfully' });
  } catch (error) {
    next(error);
  }
}

export async function updateGoal(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const goal = await goalsService.updateGoal(id, req.user!.id, req.body);
    res.json({ data: goal, message: 'Goal updated successfully' });
  } catch (error) {
    next(error);
  }
}

export async function deleteGoal(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    await goalsService.deleteGoal(id, req.user!.id);
    res.json({ message: 'Goal deleted successfully' });
  } catch (error) {
    next(error);
  }
}

export async function contributeToGoal(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const result = await goalsService.contributeToGoal(id, req.user!.id, req.body);
    res.json({ data: result, message: 'Contribution added successfully' });
  } catch (error) {
    next(error);
  }
}

export async function getGoalProgress(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    const progress = await goalsService.getGoalProgress(id, req.user!.id);
    res.json({ data: progress });
  } catch (error) {
    next(error);
  }
}
