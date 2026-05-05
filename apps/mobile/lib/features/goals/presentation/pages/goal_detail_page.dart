import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/models/models.dart';
import '../widgets/goal_dialog.dart';
import 'goals_page.dart';

final goalDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get('${ApiConstants.goals}/$id/progress');
  return response.data['data'] as Map<String, dynamic>;
});

class GoalDetailPage extends ConsumerWidget {
  final String goalId;
  const GoalDetailPage({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detailAsync = ref.watch(goalDetailProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Progress'),
        actions: [
          detailAsync.when(
            loading: () => const SizedBox(),
            error: (err, stack) => const SizedBox(),
            data: (data) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditDialog(context, ref, data['goal']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.errorLight),
                  onPressed: () => _confirmDelete(context, ref, data['goal']),
                ),
              ],
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(
          message: 'Failed to load goal',
          onRetry: () => ref.invalidate(goalDetailProvider(goalId)),
        ),
        data: (data) {
          final goalData = data['goal'] as Map<String, dynamic>;
          final goal = Goal.fromJson(goalData);
          final progress = (data['progressPercent'] ?? 0).toDouble();
          final remaining = (data['remaining'] ?? 0).toDouble();
          final requiredMonthly = data['requiredMonthlySaving'];
          final currency = goal.currency;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress circle
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: CircularProgressIndicator(
                          value: (progress / 100).clamp(0.0, 1.0),
                          strokeWidth: 12,
                          backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                          color: AppColors.savings,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${progress.toStringAsFixed(0)}%', style: AppTextStyles.displayLarge.copyWith(color: AppColors.savings)),
                          Text('saved', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(goal.title, style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
                if (goal.description != null) ...[
                  const SizedBox(height: 8),
                  Text(goal.description!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),

                // Stats cards
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Saved', value: CurrencyFormatter.format(goal.savedAmount, currency), color: AppColors.income)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Remaining', value: CurrencyFormatter.format(remaining, currency), color: AppColors.expense)),
                  ],
                ),
                if (requiredMonthly != null) ...[
                  const SizedBox(height: 12),
                  _StatCard(label: 'Required monthly saving', value: CurrencyFormatter.format(requiredMonthly.toDouble(), currency), color: AppColors.savings),
                ],
                const SizedBox(height: 32),

                // Add Contribution button
                AppButton(
                  text: 'Add Contribution',
                  icon: Icons.add,
                  width: double.infinity,
                  onPressed: () => _showContributeDialog(context, ref, goal.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showContributeDialog(BuildContext context, WidgetRef ref, String goalId) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Contribution'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: AppTextField(
          controller: amountController,
          label: 'Amount',
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: const Icon(Icons.attach_money),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              try {
                final client = ref.read(dioClientProvider);
                await client.post('${ApiConstants.goals}/$goalId/contribute', data: {'amount': amount});
                ref.invalidate(goalDetailProvider(goalId));
                ref.invalidate(goalsProvider); // Also refresh the list
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (_) {}
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> goalData) {
    showDialog(
      context: context,
      builder: (ctx) => GoalDialog(goal: Goal.fromJson(goalData)),
    ).then((value) {
      if (value == true) {
        ref.invalidate(goalDetailProvider(goalId));
        ref.invalidate(goalsProvider);
      }
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> goalData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goalData['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                final client = ref.read(dioClientProvider);
                await client.delete('${ApiConstants.goals}/${goalData['id']}');
                ref.invalidate(goalsProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to list
                }
              } catch (_) {}
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorLight)),
          ),
        ],
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.amountSmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
