import { prisma } from '../../config/database';
import { callAI } from '../../config/ai';
import { PredictionData, PredictionInsight, ForecastData } from '../../types/api.types';

export async function getPredictions(userId: string): Promise<PredictionData> {
  const now = new Date();
  const currentMonth = now.getMonth() + 1;
  const currentYear = now.getFullYear();
  
  // 1. Fetch Data for Analysis
  const [transactions, goals, budgets, user] = await Promise.all([
    prisma.transaction.findMany({
      where: { userId, date: { gte: new Date(now.getFullYear(), now.getMonth() - 5, 1) } },
      orderBy: { date: 'asc' },
    }),
    prisma.goal.findMany({ where: { userId, status: 'IN_PROGRESS' } }),
    prisma.budget.findMany({ where: { userId }, include: { category: true } }),
    prisma.user.findUniqueOrThrow({ where: { id: userId } }),
  ]);

  // 2. Process Current Month Pace
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const currentMonthTx = transactions.filter(t => t.date >= startOfMonth);
  const currentSpent = currentMonthTx.filter(t => t.type === 'EXPENSE').reduce((sum, t) => sum + t.amountInBaseCurrency, 0);
  const currentIncome = currentMonthTx.filter(t => t.type === 'INCOME').reduce((sum, t) => sum + t.amountInBaseCurrency, 0);

  const daysPassed = now.getDate();
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  const dailyPace = currentSpent / daysPassed;
  const monthlyForecast = dailyPace * daysInMonth;

  // 3. Process Historical Trends (last 6 months)
  const monthlyData: { [key: string]: { income: number; expenses: number } } = {};
  transactions.forEach(t => {
    const key = `${t.date.getFullYear()}-${t.date.getMonth() + 1}`;
    if (!monthlyData[key]) monthlyData[key] = { income: 0, expenses: 0 };
    if (t.type === 'INCOME') monthlyData[key].income += t.amountInBaseCurrency;
    else monthlyData[key].expenses += t.amountInBaseCurrency;
  });

  const months = Object.keys(monthlyData).sort();
  const avgMonthlyExpense = months.length > 1 
    ? months.slice(0, -1).reduce((sum, k) => sum + monthlyData[k].expenses, 0) / (months.length - 1)
    : monthlyForecast;

  const spendingPaceStatus = monthlyForecast > avgMonthlyExpense * 1.1 ? 'over' : (monthlyForecast < avgMonthlyExpense * 0.9 ? 'under' : 'on_track');

  // 4. Forecast Chart Data
  const forecastChart: ForecastData[] = [];
  // Actual daily spending for current month
  const dailySpending = new Array(daysInMonth).fill(0);
  currentMonthTx.filter(t => t.type === 'EXPENSE').forEach(t => {
    const day = t.date.getDate() - 1;
    dailySpending[day] += t.amountInBaseCurrency;
  });

  let cumulativeActual = 0;
  for (let i = 0; i < daysPassed; i++) {
    cumulativeActual += dailySpending[i];
    forecastChart.push({
      date: new Date(now.getFullYear(), now.getMonth(), i + 1).toISOString(),
      actual: Math.round(cumulativeActual * 100) / 100,
    });
  }

  // Forecast for remaining days
  let cumulativeForecast = cumulativeActual;
  for (let i = daysPassed; i < daysInMonth; i++) {
    cumulativeForecast += dailyPace;
    forecastChart.push({
      date: new Date(now.getFullYear(), now.getMonth(), i + 1).toISOString(),
      forecast: Math.round(cumulativeForecast * 100) / 100,
    });
  }

  // 5. Goal Completion Estimates
  const monthlySavings = months.length > 1
    ? months.slice(0, -1).reduce((sum, k) => sum + (monthlyData[k].income - monthlyData[k].expenses), 0) / (months.length - 1)
    : (currentIncome - currentSpent);
  
  const goalEstimates = goals.map(g => {
    const remaining = g.targetAmount - g.savedAmount;
    const monthsToComplete = monthlySavings > 0 ? remaining / monthlySavings : 999;
    const completionDate = new Date();
    completionDate.setMonth(completionDate.getMonth() + Math.ceil(monthsToComplete));
    
    return {
      goalId: g.id,
      title: g.title,
      estimatedCompletionDate: completionDate.toISOString(),
      confidence: monthlySavings > 0 ? 0.8 : 0.2,
    };
  });

  // 6. Financial Health Score
  // Simplified logic: Savings Rate (40%) + Budget Adherence (40%) + History (20%)
  const savingsRate = currentIncome > 0 ? ((currentIncome - currentSpent) / currentIncome) * 100 : 0;
  const budgetAdherence = budgets.length > 0 
    ? (budgets.filter(b => {
        const spent = currentMonthTx.filter(t => t.categoryId === b.categoryId && t.type === 'EXPENSE').reduce((sum, t) => sum + t.amountInBaseCurrency, 0);
        return spent <= b.amount;
      }).length / budgets.length) * 100
    : 100;
  
  const healthScore = Math.min(100, Math.max(0, (savingsRate * 0.4) + (budgetAdherence * 0.4) + 20));

  // 7. AI Insights
  const aiContext = {
    userName: user.name,
    currency: user.currency,
    currentSpent,
    monthlyForecast,
    avgMonthlyExpense,
    spendingPaceStatus,
    savingsRate: savingsRate.toFixed(1),
    healthScore: Math.round(healthScore),
    topGoals: goals.map(g => ({ title: g.title, progress: (g.savedAmount / g.targetAmount * 100).toFixed(1) })),
    budgets: budgets.map(b => ({ 
      category: b.category.name, 
      limit: b.amount, 
      spent: currentMonthTx.filter(t => t.categoryId === b.categoryId && t.type === 'EXPENSE').reduce((sum, t) => sum + t.amountInBaseCurrency, 0)
    }))
  };

  const systemPrompt = `
You are a high-end financial AI analyst. Analyze the following user data and provide 3-4 actionable, predictive insights.
Data Context:
${JSON.stringify(aiContext, null, 2)}

Output exactly 3-4 insights in JSON format. Each insight must have:
- type: "tip" (advice), "warning" (risk), "achievement" (good trend), or "forecast" (prediction).
- title: Short catchy title.
- message: 1-2 concise sentences with specific numbers.
- icon: A single emoji.
- confidence: A number between 0 and 1.

Example output format:
[
  { "type": "warning", "title": "Budget Alert", "message": "You are on track to exceed your Food budget by 15% this month.", "icon": "🍔", "confidence": 0.9 },
  ...
]
`;

  let insights: PredictionInsight[] = [];
  try {
    const aiResponse = await callAI(systemPrompt, "Generate financial predictions and insights based on my data.");
    const jsonMatch = aiResponse.match(/\[[\s\S]*\]/);
    if (jsonMatch) {
      insights = JSON.parse(jsonMatch[0]);
    }
  } catch (error) {
    console.error("Failed to generate AI insights:", error);
    insights = [
      { type: 'tip', title: 'Start Tracking', message: 'Add more transactions to get personalized AI predictions.', icon: '📈', confidence: 0.5 }
    ];
  }

  return {
    monthlySpendingForecast: Math.round(monthlyForecast * 100) / 100,
    spendingPaceStatus: spendingPaceStatus as any,
    projectedSavings: Math.round((currentIncome - monthlyForecast) * 100) / 100,
    financialHealthScore: Math.round(healthScore),
    insights,
    spendingForecastChart: forecastChart,
    savingsProjection: {
      currentSavings: Math.round((currentIncome - currentSpent) * 100) / 100,
      projectedEndMonth: Math.round((currentIncome - monthlyForecast) * 100) / 100,
      goalCompletionEstimates: goalEstimates,
    },
  };
}
