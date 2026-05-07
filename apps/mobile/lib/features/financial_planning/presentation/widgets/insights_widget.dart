import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:finance_manager/features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';

class InsightsWidget extends ConsumerWidget {
  const InsightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final budgetsAsync = ref.watch(budgetStatusProvider);

    return dashboardAsync.when(
      data: (data) {
        final budgets = budgetsAsync.value ?? [];
        final overBudgets = budgets.where((b) => b.usagePercent >= 100).length;
        final nearBudgets = budgets.where((b) => b.usagePercent >= 80 && b.usagePercent < 100).length;
        
        final savingsRate = (data['savingsRate'] as num?)?.toDouble() ?? 0.0;
        
        // Calculate health score (basic logic)
        double healthScore = 100.0;
        healthScore -= (overBudgets * 15); // -15 for each over budget
        healthScore -= (nearBudgets * 5); // -5 for each near limit
        if (savingsRate < 10) healthScore -= 20;
        else if (savingsRate < 20) healthScore -= 10;
        healthScore = healthScore.clamp(0, 100);

        final scoreColor = healthScore > 80 ? AppColors.income : (healthScore > 50 ? Colors.orange : AppColors.expense);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              // Health Score Header
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scoreColor.withValues(alpha: 0.2), scoreColor.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: healthScore / 100,
                            backgroundColor: Colors.white10,
                            color: scoreColor,
                            strokeWidth: 8,
                          ),
                        ),
                        Text(
                          healthScore.toInt().toString(),
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, color: scoreColor),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Health Score', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            healthScore > 80 ? 'Excellent financial status!' : (healthScore > 50 ? 'Stable, but can improve.' : 'Action required!'),
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (overBudgets > 0)
                _buildInsightItem(
                  'Critical: $overBudgets budget(s) exceeded!',
                  'You have spent more than your limit in $overBudgets categories.',
                  Icons.warning_amber_rounded,
                  AppColors.expense,
                ),
              if (nearBudgets > 0)
                _buildInsightItem(
                  'Warning: $nearBudgets budget(s) near limit',
                  'Consider reducing non-essential spending in these areas.',
                  Icons.info_outline,
                  Colors.orange,
                ),
              if (savingsRate > 20)
                _buildInsightItem(
                  'Great job on your savings!',
                  'Your current savings rate of $savingsRate% is above average.',
                  Icons.auto_awesome,
                  AppColors.income,
                )
              else if (savingsRate > 0)
                _buildInsightItem(
                  'Stable savings',
                  'You are saving $savingsRate% of your income. Keep it up!',
                  Icons.trending_up,
                  AppColors.primary,
                ),
              if (overBudgets == 0 && nearBudgets == 0 && budgets.isNotEmpty)
                _buildInsightItem(
                  'Healthy spending',
                  'All your budgets are well under control this month.',
                  Icons.check_circle_outline,
                  AppColors.income,
                ),
              if (budgets.isEmpty)
                _buildInsightItem(
                  'Getting started?',
                  'Set up your first budget to start getting personalized insights.',
                  Icons.lightbulb_outline,
                  AppColors.primary,
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildInsightItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
                Text(subtitle, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
