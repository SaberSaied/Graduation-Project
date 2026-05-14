import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/models/goal_model.dart';
import '../providers/goals_provider.dart';

class GoalDialog extends ConsumerStatefulWidget {
  final Goal? goal;
  const GoalDialog({super.key, this.goal});

  @override
  ConsumerState<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends ConsumerState<GoalDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _autoSaveAmountController;
  late final TextEditingController _autoSavePercentController;
  String _selectedIcon = '🎯';
  AutoSaveFrequency? _selectedFrequency;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title);
    _targetController = TextEditingController(text: widget.goal?.targetAmount.toString() ?? '');
    _autoSaveAmountController = TextEditingController(text: widget.goal?.autoSaveAmount?.toString() ?? '');
    _autoSavePercentController = TextEditingController(text: widget.goal?.autoSavePercentage?.toString() ?? '');
    _selectedIcon = widget.goal?.icon ?? '🎯';
    _selectedFrequency = widget.goal?.autoSaveFrequency;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _autoSaveAmountController.dispose();
    _autoSavePercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(goalActionProvider);

    ref.listen<AsyncValue<void>>(goalActionProvider, (previous, next) {
      if (next is AsyncError) {
        String errorMessage = 'Failed to save goal';
        final error = next.error;
        if (error is DioException) {
          errorMessage = error.response?.data?['error'] ?? error.message ?? errorMessage;
        } else {
          errorMessage = error.toString();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: AppColors.errorLight),
          );
        });
      }
    });

    return AlertDialog(
      title: Text(widget.goal == null ? 'Set Savings Goal' : 'Edit Goal'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _titleController,
              label: 'Goal Title',
              hint: 'e.g. Dream House',
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _targetController,
              label: 'Target Amount',
              hint: '0.00',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Auto-Save Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _autoSaveAmountController,
              label: 'Fixed Amount',
              hint: '0.00',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.savings_outlined),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _autoSavePercentController,
              label: 'Percentage of Income (%)',
              hint: '10',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.percent),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AutoSaveFrequency>(
              initialValue: _selectedFrequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: AutoSaveFrequency.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFrequency = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });
          },
          child: const Text('Cancel'),
        ),
        AppButton(
          text: 'Save Goal',
          isLoading: actionState.isLoading,
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _targetController.text.isEmpty) return;

    final data = {
      'title': _titleController.text,
      'targetAmount': double.parse(_targetController.text),
      'autoSaveAmount': _autoSaveAmountController.text.isNotEmpty ? double.parse(_autoSaveAmountController.text) : null,
      'autoSavePercentage': _autoSavePercentController.text.isNotEmpty ? double.parse(_autoSavePercentController.text) : null,
      'autoSaveFrequency': _selectedFrequency?.name.toUpperCase(),
      'icon': _selectedIcon,
      'currency': 'USD',
    };

    if (widget.goal != null) {
      await ref.read(goalActionProvider.notifier).updateGoal(widget.goal!.id, data);
    } else {
      await ref.read(goalActionProvider.notifier).createGoal(data);
    }

    if (mounted && !ref.read(goalActionProvider).hasError) {
      // Fix for Linux MouseTracker and Scaffold geometry error:
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }
}
