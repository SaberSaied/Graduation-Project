export interface ApiResponse<T = any> {
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T = any> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    totalCount: number;
    totalPages: number;
    hasNext: boolean;
    hasPrevious: boolean;
  };
}

export interface MonthlySummary {
  totalIncome: number;
  totalExpenses: number;
  netBalance: number;
  savingsRate: number;
  transactionCount: number;
}

export interface CategoryBreakdown {
  categoryId: string;
  name: string;
  icon: string;
  color: string;
  total: number;
  percentage: number;
  count: number;
}

export interface BudgetStatus {
  budgetId: string;
  category: string;
  categoryIcon: string;
  limit: number;
  spent: number;
  remaining: number;
  usagePercent: number;
}

export interface DashboardData {
  balance: number;
  totalIncome: number;
  totalExpenses: number;
  savingsRate: number;
  recentTransactions: any[];
  categoryBreakdown: CategoryBreakdown[];
  budgetAlerts: BudgetStatus[];
  activeGoals: any[];
}

export interface PredictionInsight {
  type: 'tip' | 'warning' | 'achievement' | 'forecast';
  title: string;
  message: string;
  icon: string;
  confidence: number;
}

export interface ForecastData {
  date: string;
  actual?: number;
  forecast?: number;
}

export interface PredictionData {
  monthlySpendingForecast: number;
  spendingPaceStatus: 'under' | 'on_track' | 'over';
  projectedSavings: number;
  financialHealthScore: number;
  insights: PredictionInsight[];
  spendingForecastChart: ForecastData[];
  savingsProjection: {
    currentSavings: number;
    projectedEndMonth: number;
    goalCompletionEstimates: Array<{
      goalId: string;
      title: string;
      estimatedCompletionDate: string;
      confidence: number;
    }>;
  };
}

export type ObligationType = 'SUBSCRIPTION' | 'BILL' | 'DEBT' | 'LOAN' | 'INSTALLMENT';
export type ObligationStatus = 'PAID' | 'UPCOMING' | 'OVERDUE' | 'PAUSED';
export type RecurringType = 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY';
export type ReminderType = 'PUSH' | 'IN_APP' | 'DASHBOARD';
export type PaymentStatus = 'COMPLETED' | 'PENDING' | 'FAILED';

export interface FinancialObligation {
  id: string;
  userId: string;
  categoryId?: string;
  title: string;
  description?: string;
  amount: number;
  currency: string;
  type: ObligationType;
  status: ObligationStatus;
  dueDate?: Date | string;
  isRecurring: boolean;
  recurringType?: RecurringType;
  startDate: Date | string;
  endDate?: Date | string;
  autoRenew?: boolean;
  totalAmount?: number;
  remainingAmount?: number;
  interestRate?: number;
  lenderInfo?: string;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface BillReminder {
  id: string;
  obligationId: string;
  userId: string;
  reminderDate: string;
  isSent: boolean;
  type: ReminderType;
}

export interface ObligationPayment {
  id: string;
  obligationId: string;
  transactionId?: string;
  amount: number;
  paymentDate: string;
  status: PaymentStatus;
}

export interface ObligationsSummary {
  totalMonthlyLiabilities: number;
  totalDebt: number;
  upcomingBillsCount: number;
  overdueCount: number;
  aiInsights: string[];
}
