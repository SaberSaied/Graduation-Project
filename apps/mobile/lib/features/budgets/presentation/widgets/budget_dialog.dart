import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../domain/models/budget_model.dart';
import '../providers/budgets_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class BudgetDialog extends ConsumerStatefulWidget {
  final Budget? budget;
  const BudgetDialog({super.key, this.budget});

  @override
  ConsumerState<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<BudgetDialog> {
  final _amountController = TextEditingController();
  final _thresholdController = TextEditingController();
  String? _selectedCategoryId;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toString();
      _thresholdController.text = (widget.budget!.alertThreshold * 100).toInt().toString();
      _selectedCategoryId = widget.budget!.categoryId;
      _selectedPeriod = widget.budget!.period;
    } else {
      _thresholdController.text = '80';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final actionState = ref.watch(budgetActionProvider);

    return AlertDialog(
      title: Text(widget.budget == null ? 'Control Spending' : 'Adjust Limit'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categoriesState.expenseCategories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}')))
                  .toList(),
              onChanged: widget.budget != null ? null : (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _amountController,
              label: 'Budget Amount',
              hint: '0.00',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BudgetPeriod>(
              initialValue: _selectedPeriod,
              decoration: const InputDecoration(labelText: 'Period'),
              items: BudgetPeriod.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPeriod = v!),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _thresholdController,
              label: 'Alert Threshold (%)',
              hint: '80',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.notifications_active_outlined),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        AppButton(
          text: 'Set Budget',
          isLoading: actionState.isLoading,
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedCategoryId == null || _amountController.text.isEmpty) return;
    
    final data = {
      'categoryId': _selectedCategoryId,
      'amount': double.parse(_amountController.text),
      'period': _selectedPeriod.name.toUpperCase(),
      'alertThreshold': double.parse(_thresholdController.text) / 100,
      'currency': 'USD',
    };

    if (widget.budget == null) {
      await ref.read(budgetActionProvider.notifier).createBudget(data);
    } else {
      await ref.read(budgetActionProvider.notifier).updateBudget(widget.budget!.id, data);
    }
    
    if (mounted && !ref.read(budgetActionProvider).hasError) {
      Navigator.pop(context);
    }
  }
}
