import { Router } from 'express';
import { ObligationsController } from './obligations.controller';
import { requireAuth } from '../../middleware/auth.middleware';

const router: Router = Router();
const controller = new ObligationsController();

router.use(requireAuth);

router.get('/', controller.getObligations);
router.get('/summary', controller.getSummary);
router.post('/', controller.createObligation);
router.put('/:id', controller.updateObligation);
router.delete('/:id', controller.deleteObligation);
router.post('/:id/pay', controller.markAsPaid);

export default router;
