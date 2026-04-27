import { prisma } from '../../config/database';
import { AppError } from '../../middleware/error.middleware';

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
      },
    },
  });

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
    deadline?: Date | null;
    icon?: string | null;
    color?: string | null;
  }
) {
  return prisma.goal.create({
    data: {
      userId,
      ...data,
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
    deadline: Date | null;
    icon: string | null;
    color: string | null;
    status: 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
  }>
) {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new AppError('Goal not found', 404);

  return prisma.goal.update({
    where: { id: goalId },
    data,
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
  data: { amount: number; note?: string | null }
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
      },
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

export async function getGoalProgress(goalId: string, userId: string) {
  const goal = await prisma.goal.findFirst({
    where: { id: goalId, userId },
    include: {
      contributions: {
        orderBy: { date: 'desc' },
      },
    },
  });

  if (!goal) throw new AppError('Goal not found', 404);

  const progressPercent = (goal.savedAmount / goal.targetAmount) * 100;
  const remaining = goal.targetAmount - goal.savedAmount;

  // Calculate required monthly saving if deadline exists
  let requiredMonthlySaving = null;
  if (goal.deadline && remaining > 0) {
    const now = new Date();
    const deadline = new Date(goal.deadline);
    const monthsLeft = Math.max(
      1,
      (deadline.getFullYear() - now.getFullYear()) * 12 + (deadline.getMonth() - now.getMonth())
    );
    requiredMonthlySaving = Math.round((remaining / monthsLeft) * 100) / 100;
  }

  return {
    goal,
    progressPercent: Math.round(progressPercent * 100) / 100,
    remaining: Math.round(remaining * 100) / 100,
    requiredMonthlySaving,
    totalContributions: goal.contributions.length,
    averageContribution:
      goal.contributions.length > 0
        ? Math.round(
            (goal.contributions.reduce((sum, c) => sum + c.amount, 0) / goal.contributions.length) * 100
          ) / 100
        : 0,
  };
}
