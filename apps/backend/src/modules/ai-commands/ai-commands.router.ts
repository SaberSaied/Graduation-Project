import { Router } from 'express';
import * as aiCommandsController from './ai-commands.controller';
import { requireAuth } from '../../middleware/auth.middleware';

const router: Router = Router();

router.post('/process', requireAuth, aiCommandsController.processPrompt);
router.post('/execute', requireAuth, aiCommandsController.executeCommands);

export default router;
