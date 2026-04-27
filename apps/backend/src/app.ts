import express, { Application } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { env } from './config/env';
import { generalLimiter, authLimiter } from './middleware/rateLimit.middleware';
import { errorMiddleware } from './middleware/error.middleware';

import { authRouter } from './modules/auth/auth.router';
import { usersRouter } from './modules/users/users.router';
import { categoriesRouter } from './modules/categories/categories.router';
import { transactionsRouter } from './modules/transactions/transactions.router';
import { budgetsRouter } from './modules/budgets/budgets.router';
import { goalsRouter } from './modules/goals/goals.router';
import { analyticsRouter } from './modules/analytics/analytics.router';
import { aiChatRouter } from './modules/ai-chat/ai-chat.router';
import { notificationsRouter } from './modules/notifications/notifications.router';

export const app:Application = express();

// ─── Security Middleware ──────────────────────────
app.use(helmet());
app.use(
  cors({
    origin: ['http://localhost:3000', 'http://127.0.0.1:3000'],
    credentials: true,
  })
);

// ─── Body Parsing ─────────────────────────────────
app.use(express.json({ limit: '10kb' }));

// ─── Authentication ───────────────────────────────
app.use('/api/v1/auth', authLimiter, authRouter);

// ─── General Rate Limiting ────────────────────────
app.use(generalLimiter);

// ─── Health Check ─────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── API Routes ───────────────────────────────────
app.use('/api/v1/users',         usersRouter);
app.use('/api/v1/categories',    categoriesRouter);
app.use('/api/v1/transactions',  transactionsRouter);
app.use('/api/v1/budgets',       budgetsRouter);
app.use('/api/v1/goals',         goalsRouter);
app.use('/api/v1/analytics',     analyticsRouter);
app.use('/api/v1/ai',            aiChatRouter);
app.use('/api/v1/notifications', notificationsRouter);

// ─── 404 Handler ──────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ─── Global Error Handler ─────────────────────────
app.use(errorMiddleware);

export default app;
