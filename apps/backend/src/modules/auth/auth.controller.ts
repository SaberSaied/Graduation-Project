import { Request, Response, NextFunction } from 'express';
import { prisma } from '../../config/database';
import { hashPassword, comparePassword, generateToken } from '../../utils/auth.utils';
import { AppError } from '../../middleware/error.middleware';
import { OAuth2Client } from 'google-auth-library';
import { env } from '../../config/env';

const googleClient = new OAuth2Client(env.GOOGLE_CLIENT_ID);

/**
 * Handle User Registration
 */
export const signUp = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      throw new AppError('Name, email, and password are required', 400);
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw new AppError('A user with this email already exists', 400);
    }

    // Hash password and create user
    const hashedPass = await hashPassword(password);
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPass,
      },
      select: {
        id: true,
        name: true,
        email: true,
        createdAt: true,
      },
    });

    // Generate JWT
    const token = generateToken(user.id);

    res.status(201).json({
      status: 'success',
      token,
      user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Handle User Login
 */
export const signIn = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      throw new AppError('Email and password are required', 400);
    }

    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user || !(await comparePassword(password, user.password))) {
      throw new AppError('Invalid email or password', 401);
    }

    // Generate JWT
    const token = generateToken(user.id);

    res.status(200).json({
      status: 'success',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Handle User Logout (Stateless for JWT)
 */
export const signOut = (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'success',
    message: 'Logged out successfully',
  });
};

/**
 * Get current session user
 */
export const getSession = async (req: Request, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw new AppError('No valid session found', 401);
    }

    const { id } = req.user;
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        createdAt: true,
      },
    });

    if (!user) {
      throw new AppError('User not found', 404);
    }

    res.status(200).json({
      status: 'success',
      user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Handle Google Sign-In
 */
export const googleSignIn = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      throw new AppError('Google ID token is required', 400);
    }

    // Verify token with Google
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    if (!payload || !payload.email) {
      throw new AppError('Invalid Google token', 401);
    }

    const { email, name, picture, email_verified } = payload;

    // Find or create user
    let user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      // Create user if not exists
      // Using a random password since they sign in via Google
      const randomPassword = await hashPassword(Math.random().toString(36).slice(-10));
      user = await prisma.user.create({
        data: {
          email,
          name: name || email.split('@')[0],
          password: randomPassword,
          image: picture,
          emailVerified: email_verified || false,
        },
      });
    }

    // Generate JWT
    const token = generateToken(user.id);

    res.status(200).json({
      status: 'success',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        image: user.image,
        createdAt: user.createdAt,
      },
    });
  } catch (error: any) {
    console.error('Google Sign-In Error:', error);
    const errorMessage = error.message || 'Google authentication failed';
    next(new AppError(`Google authentication failed: ${errorMessage}`, 401));
  }
};
