import { Request, Response, NextFunction } from 'express';
import * as predictionsService from './predictions.service';

export async function getPredictions(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = (req as any).user.id;
    const data = await predictionsService.getPredictions(userId);
    res.json({ data });
  } catch (error) {
    next(error);
  }
}
