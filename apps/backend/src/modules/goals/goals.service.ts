import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';
import { subMonths, startOfMonth, endOfMonth } from 'date-fns';

export async function getGoals(userId: string) {
  return prisma.goal.findMany({
    where: { userId },
    include: {
      contributions: {
        orderBy: { date: 'desc' },
        take: 5,
      },
    },
    orderBy: { createdAt: 'desc' },
  });
}

export async function getGoal(goalId: string, userId: string) {
  const goal = await prisma.goal.findFirst({
    where: { id: goalId, userId },
    include: {
      contributions: {
        orderBy: { date: 'desc' },
        include: { transaction: true } as any
      },
    },
  }) as any;

  if (!goal) throw new AppError('Goal not found', 404);
  return goal;
}

export async function createGoal(
  userId: string,
  data: {
    title: string;
    description?: string | null;
    targetAmount: number;
    currency: string;
    deadline?: string | null;
    icon?: string | null;
    color?: string | null;
    autoSaveAmount?: number;
    autoSavePercentage?: number;
    autoSaveFrequency?: 'DAILY' | 'WEEKLY' | 'MONTHLY';
  }
) {
  return prisma.goal.create({
    data: {
      userId,
      ...data,
      deadline: data.deadline ? new Date(data.deadline) : null,
    },
    include: { contributions: true },
  });
}

export async function updateGoal(
  goalId: string,
  userId: string,
  data: Partial<{
    title: string;
    description: string | null;
    targetAmount: number;
    deadline: string | null;
    icon: string | null;
    color: string | null;
    status: 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
    autoSaveAmount: number;
    autoSavePercentage: number;
    autoSaveFrequency: 'DAILY' | 'WEEKLY' | 'MONTHLY';
  }>
) {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new AppError('Goal not found', 404);

  const updateData: any = { ...data };
  if (data.deadline) updateData.deadline = new Date(data.deadline);

  return prisma.goal.update({
    where: { id: goalId },
    data: updateData,
    include: { contributions: true },
  });
}

export async function deleteGoal(goalId: string, userId: string) {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new AppError('Goal not found', 404);

  return prisma.goal.delete({ where: { id: goalId } });
}

export async function contributeToGoal(
  goalId: string,
  userId: string,
  data: { amount: number; note?: string | null; transactionId?: string }
) {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new AppError('Goal not found', 404);

  if (goal.status !== 'IN_PROGRESS') {
    throw new AppError('Cannot contribute to a completed or cancelled goal', 400);
  }

  const newSavedAmount = goal.savedAmount + data.amount;
  const isCompleted = newSavedAmount >= goal.targetAmount;

  // Create contribution and update goal in a transaction
  const [contribution, updatedGoal] = await prisma.$transaction([
    prisma.goalContribution.create({
      data: {
        goalId,
        amount: data.amount,
        note: data.note,
        transactionId: data.transactionId,
      } as any,
    }),
    prisma.goal.update({
      where: { id: goalId },
      data: {
        savedAmount: newSavedAmount,
        status: isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
      },
      include: { contributions: true },
    }),
  ]);

  // Create notification for milestones
  const progressPercent = (newSavedAmount / goal.targetAmount) * 100;
  const milestones = [25, 50, 75, 100];
  const previousPercent = ((newSavedAmount - data.amount) / goal.targetAmount) * 100;

  for (const milestone of milestones) {
    if (previousPercent < milestone && progressPercent >= milestone) {
      await prisma.notification.create({
        data: {
          userId,
          type: 'GOAL_PROGRESS',
          title: milestone === 100 ? '🎉 Goal Completed!' : `🎯 ${milestone}% Milestone!`,
          message: milestone === 100
            ? `Congratulations! You've reached your "${goal.title}" goal of ${goal.targetAmount} ${goal.currency}!`
            : `You've reached ${milestone}% of your "${goal.title}" goal! Keep going!`,
          metadata: { goalId, milestone, progressPercent },
        },
      });
    }
  }

  return { contribution, goal: updatedGoal };
}

export async function getGoalAnalytics(userId: string) {
  const now = new Date();
  const last6Months = subMonths(now, 6);

  // Get contributions by month
  const contributions = await prisma.goalContribution.findMany({
    where: {
      goal: { userId },
      date: { gte: last6Months },
    },
    orderBy: { date: 'asc' },
  });

  const monthlyData: Record<string, number> = {};
  for (let i = 0; i < 6; i++) {
    const monthDate = subMonths(now, i);
    const key = `${monthDate.getFullYear()}-${monthDate.getMonth() + 1}`;
    monthlyData[key] = 0;
  }

  contributions.forEach(c => {
    const key = `${c.date.getFullYear()}-${c.date.getMonth() + 1}`;
    if (monthlyData[key] !== undefined) {
      monthlyData[key] += c.amount;
    }
  });

  const trend = Object.entries(monthlyData).map(([month, amount]) => ({
    month,
    amount,
  })).sort((a, b) => a.month.localeCompare(b.month));

  // Saving consistency (average per month)
  const totalSaved = trend.reduce((sum, d) => sum + d.amount, 0);
  const averageSaved = totalSaved / trend.length;

  return {
    trend,
    averageSaved: Math.round(averageSaved * 100) / 100,
    totalSavedInPeriod: Math.round(totalSaved * 100) / 100,
  };
}

export async function getGoalProgress(goalId: string, userId: string) {
  const goal = await getGoal(goalId, userId);
  const progressPercent = (goal.savedAmount / goal.targetAmount) * 100;
  const remaining = goal.targetAmount - goal.savedAmount;

  // Calculate projected completion date based on average monthly contribution
  const now = new Date();
  const last3Months = subMonths(now, 3);
  const recentContributions = await prisma.goalContribution.aggregate({
    where: {
      goalId,
      date: { gte: last3Months },
    },
    _sum: { amount: true },
  });

  const averageMonthly = (recentContributions._sum.amount || 0) / 3;
  let projectedMonths = null;
  let projectedDate = null;

  if (averageMonthly > 0 && remaining > 0) {
    projectedMonths = Math.ceil(remaining / averageMonthly);
    projectedDate = new Date();
    projectedDate.setMonth(projectedDate.getMonth() + projectedMonths);
  }

  return {
    goal,
    progressPercent: Math.round(progressPercent * 100) / 100,
    remaining: Math.round(remaining * 100) / 100,
    projectedMonths,
    projectedDate,
    averageMonthly: Math.round(averageMonthly * 100) / 100,
  };
}
