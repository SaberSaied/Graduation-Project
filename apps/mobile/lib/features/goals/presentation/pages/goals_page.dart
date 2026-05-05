import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/models/models.dart';
import '../widgets/goal_dialog.dart';

final goalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get(ApiConstants.goals);
  final List data = response.data['data'] ?? [];
  return data.map((json) => Goal.fromJson(json)).toList();
});

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showGoalDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(goalsProvider),
        child: goalsAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading goals...'),
          error: (e, _) => AppErrorWidget(
            message: 'Failed to load goals',
            onRetry: () => ref.invalidate(goalsProvider),
          ),
          data: (goals) {
            if (goals.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.flag_outlined,
                title: 'No savings goals',
                subtitle: 'Set a goal and start saving towards it',
                actionLabel: 'Create Goal',
                onAction: () => _showGoalDialog(context, ref),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = goal.targetAmount > 0 ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;

                return GestureDetector(
                  onTap: () => context.push('/goals/${goal.id}'),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.savings.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(goal.icon ?? '🎯', style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(goal.title, style: AppTextStyles.headlineSmall),
                                    const SizedBox(height: 2),
                                    Builder(
                                      builder: (context) {
                                        String statusText = 'In progress';
                                        Color statusColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
                                        
                                        if (goal.status == 'COMPLETED') {
                                          statusText = '✅ Completed';
                                          statusColor = AppColors.income;
                                        } else if (goal.status == 'CANCELLED') {
                                          statusText = '❌ Cancelled';
                                          statusColor = AppColors.errorLight;
                                        }
                                        
                                        return Text(statusText, style: AppTextStyles.bodySmall.copyWith(color: statusColor));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(CurrencyFormatter.format(goal.savedAmount, goal.currency), style: AppTextStyles.amountSmall.copyWith(color: AppColors.savings)),
                              Text(CurrencyFormatter.format(goal.targetAmount, goal.currency), style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                              color: AppColors.savings,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% complete',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => const GoalDialog(),
    ).then((value) {
      if (value == true) ref.invalidate(goalsProvider);
    });
  }
}

