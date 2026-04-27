import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

export function errorMiddleware(err: Error, req: Request, res: Response, _next: NextFunction) {
  console.error('❌ Error:', err);

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: err.message,
    });
  }

  // Prisma known errors
  if ((err as any).code === 'P2002') {
    return res.status(409).json({
      error: 'A record with this data already exists.',
    });
  }

  if ((err as any).code === 'P2025') {
    return res.status(404).json({
      error: 'Record not found.',
    });
  }

  // Default server error
  return res.status(500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message,
  });
}
