import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/models/models.dart';
import '../../../settings/presentation/pages/categories_page.dart';

final budgetsProvider = FutureProvider.autoDispose<List<Budget>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get(ApiConstants.budgets);
  final List data = response.data['data'] ?? [];
  return data.map((json) => Budget.fromJson(json)).toList();
});

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showBudgetDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(budgetsProvider),
        child: budgetsAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading budgets...'),
          error: (e, _) => AppErrorWidget(
            message: 'Failed to load budgets',
            onRetry: () => ref.invalidate(budgetsProvider),
          ),
          data: (budgets) {
            if (budgets.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.pie_chart_outline,
                title: 'No budgets set',
                subtitle: 'Set a budget to control your spending',
                actionLabel: 'Create Budget',
                onAction: () => _showBudgetDialog(context, ref),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final spent = budget.spent ?? 0;
                final limit = budget.amount;
                final usagePercent = limit > 0 ? (spent / limit * 100).toInt() : 0;
                final bool isOver = usagePercent >= 100;

                return Card(
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
                                color: (isOver ? AppColors.errorLight : AppColors.primaryLight).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(budget.categoryIcon ?? '📦', style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(budget.categoryName ?? 'Category', style: AppTextStyles.headlineSmall),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _showBudgetDialog(context, ref, budget);
                                } else if (value == 'delete') {
                                  _confirmDelete(context, ref, budget);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit Limit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete Budget')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Spent', style: AppTextStyles.bodySmall),
                                const SizedBox(height: 4),
                                Text(CurrencyFormatter.format(spent, budget.currency), style: AppTextStyles.titleMedium),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Limit', style: AppTextStyles.bodySmall),
                                const SizedBox(height: 4),
                                Text(CurrencyFormatter.format(limit, budget.currency), style: AppTextStyles.titleMedium),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (usagePercent / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                            color: isOver ? AppColors.errorLight : AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$usagePercent% used', style: AppTextStyles.labelSmall),
                            if (isOver)
                              Text(
                                'Exceeded by ${CurrencyFormatter.format(spent - limit, budget.currency)}',
                                style: const TextStyle(color: AppColors.errorLight, fontSize: 12),
                              ),
                          ],
                        ),
                      ],
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

  void _showBudgetDialog(BuildContext context, WidgetRef ref, [Budget? budget]) {
    showDialog(
      context: context,
      builder: (ctx) => _BudgetDialog(budget: budget),
    ).then((value) {
      if (value == true) ref.invalidate(budgetsProvider);
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Budget budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to remove the budget for ${budget.categoryName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                final client = ref.read(dioClientProvider);
                await client.delete('${ApiConstants.budgets}/${budget.id}');
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(budgetsProvider);
              } catch (_) {}
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorLight)),
          ),
        ],
      ),
    );
  }
}

class _BudgetDialog extends ConsumerStatefulWidget {
  final Budget? budget;
  const _BudgetDialog({this.budget});

  @override
  ConsumerState<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<_BudgetDialog> {
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toString();
      _selectedCategoryId = widget.budget!.categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return AlertDialog(
      title: Text(widget.budget == null ? 'Set Budget' : 'Edit Budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          categoriesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => const Text('Error loading categories'),
            data: (categories) {
              final expenseCategories = categories.where((c) => c.type == 'EXPENSE').toList();
              return DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                disabledHint: widget.budget != null ? Text(widget.budget!.categoryName ?? '') : null,
                items: expenseCategories.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'))).toList(),
                onChanged: widget.budget != null ? null : (v) => setState(() => _selectedCategoryId = v),
              );
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _amountController,
            label: 'Monthly Limit',
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.attach_money),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        AppButton(
          text: 'Save',
          isLoading: _isLoading,
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedCategoryId == null || _amountController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(dioClientProvider);
      final amount = double.parse(_amountController.text);
      final now = DateTime.now();
      
      final data = {
        'categoryId': _selectedCategoryId,
        'amount': amount,
        'month': now.month,
        'year': now.year,
        'currency': 'USD',
      };

      if (widget.budget == null) {
        await client.post(ApiConstants.budgets, data: data);
      } else {
        await client.patch('${ApiConstants.budgets}/${widget.budget!.id}', data: {'amount': amount});
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
}
