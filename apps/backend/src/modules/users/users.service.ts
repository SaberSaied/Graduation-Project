import { prisma } from '../../config/database';

export async function getUserById(userId: string) {
  return prisma.user.findUniqueOrThrow({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      name: true,
      image: true,
      currency: true,
      financialGoal: true,
      createdAt: true,
      updatedAt: true,
    },
  });
}

export async function updateUser(userId: string, data: { name?: string; currency?: string; financialGoal?: string }) {
  return prisma.user.update({
    where: { id: userId },
    data,
    select: {
      id: true,
      email: true,
      name: true,
      image: true,
      currency: true,
      financialGoal: true,
      createdAt: true,
      updatedAt: true,
    },
  });
}

export async function deleteUser(userId: string) {
  return prisma.user.delete({
    where: { id: userId },
  });
}

export async function getFinancialSummary(userId: string) {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  const [transactions, goals, user] = await Promise.all([
    prisma.transaction.findMany({
      where: {
        userId,
        date: { gte: startOfMonth, lt: endOfMonth },
      },
    }),
    prisma.goal.findMany({
      where: { userId, status: 'IN_PROGRESS' },
    }),
    prisma.user.findUniqueOrThrow({ where: { id: userId } }),
  ]);

  const totalIncome = transactions
    .filter((t) => t.type === 'INCOME')
    .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  const totalExpenses = transactions
    .filter((t) => t.type === 'EXPENSE')
    .reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  const totalGoalsSaved = goals.reduce((sum, g) => sum + g.savedAmount, 0);
  const totalGoalsTarget = goals.reduce((sum, g) => sum + g.targetAmount, 0);

  return {
    currency: user.currency,
    thisMonth: {
      totalIncome: Math.round(totalIncome * 100) / 100,
      totalExpenses: Math.round(totalExpenses * 100) / 100,
      netBalance: Math.round((totalIncome - totalExpenses) * 100) / 100,
      savingsRate: totalIncome > 0
        ? Math.round(((totalIncome - totalExpenses) / totalIncome) * 100)
        : 0,
      transactionCount: transactions.length,
    },
    goals: {
      activeCount: goals.length,
      totalSaved: Math.round(totalGoalsSaved * 100) / 100,
      totalTarget: Math.round(totalGoalsTarget * 100) / 100,
      overallProgress: totalGoalsTarget > 0
        ? Math.round((totalGoalsSaved / totalGoalsTarget) * 100)
        : 0,
    },
  };
}
