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
