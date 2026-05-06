import { prisma } from '../../config/database';
import { AIAction } from './ai-commands.schema';
import * as transactionsService from '../transactions/transactions.service';
import * as categoriesService from '../categories/categories.service';
import * as budgetsService from '../budgets/budgets.service';
import * as goalsService from '../goals/goals.service';

export async function executeBatchActions(userId: string, actions: AIAction[]) {
  return await prisma.$transaction(async (tx) => {
    const results = [];

    for (const action of actions) {
      switch (action.type) {
        case 'CREATE_CATEGORY': {
          const result = await categoriesService.createCategory(userId, {
            name: action.data.name,
            icon: action.data.icon || '📁',
            color: action.data.color || '#9E9E9E',
            type: action.data.type,
          });
          results.push({ type: action.type, result });
          break;
        }

        case 'CREATE_TRANSACTION': {
          // Find or create category
          let category = await tx.category.findFirst({
            where: {
              userId,
              name: { contains: action.data.category, mode: 'insensitive' },
            },
          });

          if (!category) {
            category = await tx.category.create({
              data: {
                userId,
                name: action.data.category,
                icon: '📁',
                color: '#9E9E9E',
                type: action.data.type,
              },
            });
          }

          const result = await transactionsService.createTransaction(userId, {
            categoryId: category.id,
            type: action.data.type,
            amount: Number(action.data.amount),
            currency: action.data.currency || 'USD',
            title: action.data.title,
            date: action.data.date ? new Date(action.data.date) : new Date(),
            isRecurring: !!action.data.isRecurring,
            recurringInterval: action.data.recurringInterval,
          });
          results.push({ type: action.type, result });
          break;
        }

        case 'CREATE_GOAL': {
          const result = await goalsService.createGoal(userId, {
            title: action.data.title,
            targetAmount: Number(action.data.targetAmount),
            currency: action.data.currency || 'USD',
            deadline: action.data.deadline ? new Date(action.data.deadline) : null,
            description: action.data.description,
            icon: action.data.icon || '🎯',
            color: action.data.color || '#2196F3',
          });
          results.push({ type: action.type, result });
          break;
        }

        case 'CONTRIBUTE_TO_GOAL': {
          const goal = await tx.goal.findFirst({
            where: {
              userId,
              title: { contains: action.data.goalTitle, mode: 'insensitive' },
              status: 'IN_PROGRESS',
            },
          });

          if (goal) {
            const result = await goalsService.contributeToGoal(goal.id, userId, {
              amount: Number(action.data.amount),
              note: 'Added via AI Command',
            });
            results.push({ type: action.type, result });
          }
          break;
        }

        case 'CREATE_BUDGET': {
          let category = await tx.category.findFirst({
            where: {
              userId,
              name: { contains: action.data.category, mode: 'insensitive' },
            },
          });

          if (!category) {
            category = await tx.category.create({
              data: {
                userId,
                name: action.data.category,
                icon: '📁',
                color: '#9E9E9E',
                type: 'EXPENSE',
              },
            });
          }

          const result = await budgetsService.createBudget(userId, {
            categoryId: category.id,
            amount: Number(action.data.amount),
            currency: action.data.currency || 'USD',
            month: Number(action.data.month),
            year: Number(action.data.year),
          });
          results.push({ type: action.type, result });
          break;
        }

        case 'CREATE_REMINDER': {
          const result = await (tx as any).reminder.create({
            data: {
              userId,
              title: action.data.title,
              date: new Date(action.data.date),
            },
          });
          results.push({ type: action.type, result });
          break;
        }

        case 'CREATE_NOTE': {
          const result = await (tx as any).note.create({
            data: {
              userId,
              content: action.data.content,
            },
          });
          results.push({ type: action.type, result });
          break;
        }
      }
    }

    return results;
  });
}
