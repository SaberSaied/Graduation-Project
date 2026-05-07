import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:finance_manager/core/utils/currency_formatter.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';

class BudgetSummaryWidget extends ConsumerWidget {
  const BudgetSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(budgetStatusProvider);

    return statusAsync.when(
      data: (statuses) {
        if (statuses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No active budgets for this month'),
          );
        }

        // Only show top 3 on dashboard summary
        final topBudgets = statuses.take(3).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              ...topBudgets.map((status) {
                final usage = status.usagePercent / 100;
                final isWarning = usage >= 0.8;
                final isOver = usage >= 1.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(status.categoryIcon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(status.category, style: AppTextStyles.bodyMedium),
                            ],
                          ),
                          Text(
                            '${status.usagePercent}%',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isOver ? AppColors.expense : (isWarning ? Colors.orange : null),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: usage.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          color: isOver ? AppColors.expense : (isWarning ? Colors.orange : AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${CurrencyFormatter.format((status.spent as num).toDouble(), 'USD')} spent',
                            style: AppTextStyles.labelSmall,
                          ),
                          Text(
                            'Limit: ${CurrencyFormatter.format((status.limit as num).toDouble(), 'USD')}',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              if (statuses.length > 3)
                TextButton(
                  onPressed: () {
                    // Navigate to full budgets view or expand
                  },
                  child: Text('View ${statuses.length - 3} more budgets', style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (err, _) => Center(child: Text('Error loading budgets')),
    );
  }
}
