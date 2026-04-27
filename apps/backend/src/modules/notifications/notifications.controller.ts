import { Request, Response, NextFunction } from 'express';
import * as notificationsService from './notifications.service';

export async function getNotifications(req: Request, res: Response, next: NextFunction) {
  try {
    const page = req.query.page ? parseInt(req.query.page as string) : 1;
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 20;
    const result = await notificationsService.getNotifications(req.user!.id, page, limit);
    res.json(result);
  } catch (error) {
    next(error);
  }
}

export async function markAsRead(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    await notificationsService.markAsRead(id, req.user!.id);
    res.json({ message: 'Notification marked as read' });
  } catch (error) {
    next(error);
  }
}

export async function markAllAsRead(req: Request, res: Response, next: NextFunction) {
  try {
    const count = await notificationsService.markAllAsRead(req.user!.id);
    res.json({ message: `${count} notifications marked as read` });
  } catch (error) {
    next(error);
  }
}

export async function deleteNotification(req: Request, res: Response, next: NextFunction) {
  try {
    const id = req.params.id as string;
    await notificationsService.deleteNotification(id, req.user!.id);
    res.json({ message: 'Notification deleted' });
  } catch (error) {
    next(error);
  }
}

export async function getUnreadCount(req: Request, res: Response, next: NextFunction) {
  try {
    const count = await notificationsService.getUnreadCount(req.user!.id);
    res.json({ data: { count } });
  } catch (error) {
    next(error);
  }
}
