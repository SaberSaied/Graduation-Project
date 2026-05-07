import { Router } from 'express';
import { requireAuth } from '../../middleware/auth.middleware';
import * as predictionsController from './predictions.controller';

export const predictionsRouter: Router = Router();

predictionsRouter.use(requireAuth);

predictionsRouter.get('/', predictionsController.getPredictions);
