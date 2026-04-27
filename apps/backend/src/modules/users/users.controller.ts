import { Request, Response, NextFunction } from 'express';
import * as usersService from './users.service';

export async function getMe(req: Request, res: Response, next: NextFunction) {
  try {
    const user = await usersService.getUserById(req.user!.id);
    res.json({ data: user });
  } catch (error) {
    next(error);
  }
}

export async function updateMe(req: Request, res: Response, next: NextFunction) {
  try {
    const user = await usersService.updateUser(req.user!.id, req.body);
    res.json({ data: user, message: 'Profile updated successfully' });
  } catch (error) {
    next(error);
  }
}

export async function deleteMe(req: Request, res: Response, next: NextFunction) {
  try {
    await usersService.deleteUser(req.user!.id);
    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    next(error);
  }
}

export async function getFinancialSummary(req: Request, res: Response, next: NextFunction) {
  try {
    const summary = await usersService.getFinancialSummary(req.user!.id);
    res.json({ data: summary });
  } catch (error) {
    next(error);
  }
}
