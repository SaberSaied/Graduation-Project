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
                                    Text(
                                      goal.status == 'COMPLETED' ? '✅ Completed' : 'In progress',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: goal.status == 'COMPLETED' ? AppColors.income : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                                      ),
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
      builder: (ctx) => const _GoalDialog(),
    ).then((value) {
      if (value == true) ref.invalidate(goalsProvider);
    });
  }
}

class _GoalDialog extends ConsumerStatefulWidget {
  const _GoalDialog();

  @override
  ConsumerState<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends ConsumerState<_GoalDialog> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  String _selectedIcon = '🎯';
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Savings Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(controller: _titleController, label: 'Title', hint: 'e.g. New Car'),
          const SizedBox(height: 16),
          AppTextField(
            controller: _targetController,
            label: 'Target Amount',
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.attach_money),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Icon',
            hint: 'Emoji',
            onChanged: (v) => setState(() => _selectedIcon = v),
            controller: TextEditingController(text: _selectedIcon),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.date_range),
            title: Text(_deadline == null
                ? 'Target Date (Optional)'
                : 'Target Date: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2050),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        AppButton(text: 'Create', isLoading: _isLoading, onPressed: _save),
      ],
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _targetController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(dioClientProvider);
      await client.post(ApiConstants.goals, data: {
        'title': _titleController.text,
        'targetAmount': double.parse(_targetController.text),
        'icon': _selectedIcon,
        'currency': 'USD',
        if (_deadline != null) 'deadline': _deadline!.toIso8601String(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
}

