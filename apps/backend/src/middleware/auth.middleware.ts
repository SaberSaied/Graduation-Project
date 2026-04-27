import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { verifyToken } from '../utils/auth.utils';
import { AppError } from './error.middleware';

/**
 * Middleware to require authentication via manual JWT Bearer Token
 */
export const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
  try {
    // 1. Get token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError('Unauthorized - No token provided', 401);
    }

    const token = authHeader.split(' ')[1];

    // 2. Verify token
    const decoded = verifyToken(token);
    if (!decoded) {
      throw new AppError('Unauthorized - Invalid or expired token', 401);
    }

    // 3. Find user in database
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
    });

    if (!user) {
      throw new AppError('Unauthorized - User no longer exists', 401);
    }

    // 4. Attach user to request
    // We only attach what's needed or match the Express.Request interface
    req.user = {
      id: user.id,
      email: user.email,
      name: user.name,
      image: user.image,
      currency: user.currency,
      financialGoal: user.financialGoal,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };

    next();
  } catch (error) {
    next(error);
  }
};
