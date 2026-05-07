import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:finance_manager/core/utils/currency_formatter.dart';
import 'package:finance_manager/features/dashboard/presentation/providers/dashboard_provider.dart';

class MonthlySummaryWidget extends ConsumerWidget {
  const MonthlySummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return dashboardState.when(
      data: (data) {
        final income = (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
        final expense = (data['totalExpenses'] as num?)?.toDouble() ?? 0.0;
        final savings = income - expense;
        final savingsRate = (data['savingsRate'] as num?)?.toDouble() ?? 0.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatItem(
                    'Income',
                    income,
                    AppColors.income,
                    Icons.arrow_upward,
                  ),
                  const SizedBox(width: 12),
                  _buildStatItem(
                    'Spending',
                    expense,
                    AppColors.expense,
                    Icons.arrow_forward,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircularProgressIndicator(
                      value: (savingsRate / 100).clamp(0, 1),
                      backgroundColor: Colors.white24,
                      color: AppColors.income,
                      strokeWidth: 6,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Savings', style: AppTextStyles.labelLarge),
                          Text(
                            CurrencyFormatter.format(savings, 'USD'),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.income,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rate', style: AppTextStyles.labelSmall),
                        Text('$savingsRate%', style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(label, style: AppTextStyles.labelSmall),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                CurrencyFormatter.format(amount, 'USD'),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
