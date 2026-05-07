import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validate.middleware';
import { getGoals, getGoal, createGoal, updateGoal, deleteGoal, contributeToGoal, getGoalProgress, getGoalAnalytics } from './goals.controller';
import { createGoalSchema, updateGoalSchema, contributeSchema } from './goals.schema';

export const goalsRouter: Router = Router();

goalsRouter.use(requireAuth);

goalsRouter.get('/', getGoals);
goalsRouter.get('/analytics', getGoalAnalytics);
goalsRouter.get('/:id', getGoal);
goalsRouter.post('/', validate(createGoalSchema), createGoal);
goalsRouter.patch('/:id', validate(updateGoalSchema), updateGoal);
goalsRouter.delete('/:id', deleteGoal);
goalsRouter.post('/:id/contribute', validate(contributeSchema), contributeToGoal);
goalsRouter.get('/:id/progress', getGoalProgress);
