import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { getDashboard, getMonthlyReport, getTrends, getTopCategories, getInsights } from './analytics.controller';

export const analyticsRouter: Router = Router();
    
analyticsRouter.use(requireAuth);

analyticsRouter.get('/dashboard', getDashboard);
analyticsRouter.get('/monthly-report', getMonthlyReport);
analyticsRouter.get('/trends', getTrends);
analyticsRouter.get('/top-categories', getTopCategories);
analyticsRouter.get('/insights', getInsights);
