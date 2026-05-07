import { FinancialObligation, ObligationsSummary, ObligationType, ObligationStatus, RecurringType } from '../../types/api.types';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { prisma } from '../../config/database';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

export class ObligationsService {
  async getObligations(userId: string, type?: ObligationType) {
    return prisma.financialObligation.findMany({
      where: {
        userId,
        ...(type && { type }),
      },
      orderBy: {
        dueDate: 'asc',
      },
      include: {
        category: true,
        reminders: true,
        payments: true,
      },
    });
  }

  async createObligation(userId: string, data: any) {
    return prisma.financialObligation.create({
      data: {
        ...data,
        userId,
      },
    });
  }

  async updateObligation(id: string, userId: string, data: any) {
    return prisma.financialObligation.update({
      where: { id, userId },
      data,
    });
  }

  async deleteObligation(id: string, userId: string) {
    return prisma.financialObligation.delete({
      where: { id, userId },
    });
  }

  async getObligationsSummary(userId: string): Promise<ObligationsSummary> {
    const obligations = await prisma.financialObligation.findMany({
      where: { userId },
    });

    const totalMonthlyLiabilities = obligations
      .filter((o: any) => o.type === 'SUBSCRIPTION' || o.type === 'BILL' || o.type === 'INSTALLMENT')
      .reduce((sum: number, o: any) => sum + Number(o.amount), 0);

    const totalDebt = obligations
      .filter((o: any) => o.type === 'DEBT' || o.type === 'LOAN')
      .reduce((sum: number, o: any) => sum + Number(o.remainingAmount || o.amount), 0);

    const now = new Date();
    const upcomingBillsCount = obligations.filter(
      (o: any) => o.status === 'UPCOMING' && o.dueDate && new Date(o.dueDate) > now
    ).length;

    const overdueCount = obligations.filter(
      (o: any) => o.status === 'OVERDUE' || (o.dueDate && new Date(o.dueDate) < now && o.status !== 'PAID')
    ).length;

    const aiInsights = await this.generateAiInsights(obligations);

    return {
      totalMonthlyLiabilities,
      totalDebt,
      upcomingBillsCount,
      overdueCount,
      aiInsights,
    };
  }

  private async generateAiInsights(obligations: any[]): Promise<string[]> {
    if (obligations.length === 0) return ['Add your first obligation to get AI insights!'];

    try {
      const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
      const context = JSON.stringify(
        obligations.map(o => ({
          title: o.title,
          type: o.type,
          amount: o.amount,
          status: o.status,
          remaining: o.remainingAmount,
        }))
      );

      const prompt = `
        As a financial advisor, analyze these financial obligations and provide 3 short, actionable insights.
        Focus on: debt risk, subscription waste, repayment optimization.
        Obligations: ${context}
        Output ONLY a JSON array of 3 strings. Example: ["Insight 1", "Insight 2", "Insight 3"]
      `;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text().trim();
      
      // Clean up the response if it contains markdown code blocks
      const jsonStr = text.replace(/```json|```/g, '').trim();
      return JSON.parse(jsonStr);
    } catch (error) {
      console.error('Error generating AI insights for obligations:', error);
      return ['AI is currently analyzing your obligations... Check back soon!'];
    }
  }

  async markAsPaid(id: string, userId: string, amount: number) {
    return prisma.$transaction(async (tx) => {
      const obligation = await tx.financialObligation.findUnique({
        where: { id, userId },
      });

      if (!obligation) throw new Error('Obligation not found');

      // Create payment record
      const payment = await tx.obligationPayment.create({
        data: {
          obligationId: id,
          amount,
          status: 'COMPLETED',
        },
      });

      // Update remaining amount for debts
      if (obligation.type === 'DEBT' || obligation.type === 'LOAN' || obligation.type === 'INSTALLMENT') {
        const newRemaining = (obligation.remainingAmount || obligation.amount) - amount;
        await tx.financialObligation.update({
          where: { id },
          data: {
            remainingAmount: Math.max(0, newRemaining),
            status: newRemaining <= 0 ? 'PAID' : 'UPCOMING',
          },
        });
      } else {
        // For bills/subscriptions, just update status or move to next date if recurring
        if (obligation.isRecurring && obligation.dueDate) {
          const nextDueDate = this.calculateNextDueDate(obligation.dueDate, obligation.recurringType!);
          await tx.financialObligation.update({
            where: { id },
            data: {
              dueDate: nextDueDate,
              status: 'UPCOMING',
            },
          });
        } else {
          await tx.financialObligation.update({
            where: { id },
            data: { status: 'PAID' },
          });
        }
      }

      return payment;
    });
  }

  private calculateNextDueDate(current: Date, type: RecurringType): Date {
    const next = new Date(current);
    if (type === 'DAILY') next.setDate(next.getDate() + 1);
    else if (type === 'WEEKLY') next.setDate(next.getDate() + 7);
    else if (type === 'MONTHLY') next.setMonth(next.getMonth() + 1);
    else if (type === 'YEARLY') next.setFullYear(next.getFullYear() + 1);
    return next;
  }
}
