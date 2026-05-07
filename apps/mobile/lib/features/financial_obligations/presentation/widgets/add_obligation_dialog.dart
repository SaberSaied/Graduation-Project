import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_obligation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/obligations_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';

class AddObligationDialog extends ConsumerStatefulWidget {
  const AddObligationDialog({super.key});

  @override
  ConsumerState<AddObligationDialog> createState() => _AddObligationDialogState();
}

class _AddObligationDialogState extends ConsumerState<AddObligationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _lenderInfoController = TextEditingController();
  final _descriptionController = TextEditingController();

  ObligationType _selectedType = ObligationType.bill;
  bool _isRecurring = false;
  String _recurringType = 'MONTHLY';
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  bool _autoRenew = true;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _totalAmountController.dispose();
    _interestRateController.dispose();
    _lenderInfoController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(obligationActionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Obligation', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Type Selector
                _buildTypeSelector(),
                const SizedBox(height: 24),

                AppTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'e.g. Netflix, Rent, Car Loan',
                  validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _amountController,
                        label: _selectedType == ObligationType.loan || _selectedType == ObligationType.debt 
                            ? 'Installment Amount' 
                            : 'Amount',
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.attach_money),
                        validator: (v) => v?.isEmpty ?? true ? 'Amount is required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDatePicker(
                        context, 
                        'Start Date', 
                        _startDate, 
                        (date) => setState(() => _startDate = date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_selectedType == ObligationType.loan || _selectedType == ObligationType.debt) ...[
                  AppTextField(
                    controller: _totalAmountController,
                    label: 'Total Principal Amount',
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _interestRateController,
                          label: 'Interest Rate (%)',
                          hint: '0.0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          controller: _lenderInfoController,
                          label: 'Lender/Recipient',
                          hint: 'Name',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Recurring Options
                SwitchListTile(
                  title: const Text('Recurring Payment'),
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                  activeThumbColor: AppColors.primaryLight,
                  contentPadding: EdgeInsets.zero,
                ),
                
                if (_isRecurring) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _recurringType,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                      DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                      DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
                    ],
                    onChanged: (v) => setState(() => _recurringType = v!),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_selectedType == ObligationType.subscription)
                  SwitchListTile(
                    title: const Text('Auto Renew'),
                    value: _autoRenew,
                    onChanged: (v) => setState(() => _autoRenew = v),
                    activeThumbColor: AppColors.primaryLight,
                    contentPadding: EdgeInsets.zero,
                  ),

                _buildDatePicker(
                  context, 
                  'Next Due Date', 
                  _dueDate ?? DateTime.now().add(const Duration(days: 30)), 
                  (date) => setState(() => _dueDate = date),
                  isOptional: true,
                  currentValue: _dueDate,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'Create Obligation',
                  isLoading: actionState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ObligationType.values.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedType = type);
              },
              selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryLight : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, 
    String label, 
    DateTime date, 
    Function(DateTime) onPicked,
    {bool isOptional = false, DateTime? currentValue}
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: currentValue ?? date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
        ),
        child: Text(
          currentValue == null && isOptional 
              ? 'Select Date' 
              : '${date.day}/${date.month}/${date.year}',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'title': _titleController.text,
      'amount': double.parse(_amountController.text),
      'currency': 'USD',
      'type': _selectedType.name.toUpperCase(),
      'status': 'UPCOMING',
      'isRecurring': _isRecurring,
      'recurringType': _isRecurring ? _recurringType : null,
      'startDate': _startDate.toIso8601String(),
      'dueDate': _dueDate?.toIso8601String(),
      'autoRenew': _selectedType == ObligationType.subscription ? _autoRenew : null,
      'totalAmount': _totalAmountController.text.isNotEmpty ? double.parse(_totalAmountController.text) : null,
      'interestRate': _interestRateController.text.isNotEmpty ? double.parse(_interestRateController.text) : null,
      'lenderInfo': _lenderInfoController.text,
      'description': _descriptionController.text,
    };

    await ref.read(obligationActionProvider.notifier).createObligation(data);
    
    if (mounted && !ref.read(obligationActionProvider).hasError) {
      Navigator.pop(context);
    }
  }
}
