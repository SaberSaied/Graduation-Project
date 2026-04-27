import { Router } from 'express';
import * as authController from './auth.controller';
import { requireAuth } from '../../middleware/auth.middleware';

const router:Router = Router();

// Routes mapped to match the previous Better-Auth endpoints used by the Flutter app
router.post('/sign-up/email', authController.signUp);
router.post('/sign-in/email', authController.signIn);
router.post('/sign-out', authController.signOut);
router.post('/google', authController.googleSignIn);
router.get('/get-session', requireAuth, authController.getSession);

export { router as authRouter };
