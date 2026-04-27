import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
} from './notifications.controller';

export const notificationsRouter: Router = Router();

notificationsRouter.use(requireAuth);

notificationsRouter.get('/', getNotifications);
notificationsRouter.get('/unread-count', getUnreadCount);
notificationsRouter.patch('/:id/read', markAsRead);
notificationsRouter.patch('/read-all', markAllAsRead);
notificationsRouter.delete('/:id', deleteNotification);
