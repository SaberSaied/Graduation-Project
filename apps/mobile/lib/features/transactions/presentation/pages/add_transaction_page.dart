import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../goals/domain/models/goal_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'EXPENSE';
  String? _categoryId;
  String? _goalId;
  String? _budgetId;
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _analysisResult;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      if (_categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = ref.read(dioClientProvider);
      await client.post(ApiConstants.transactions, data: {
        'title': _titleController.text.trim(),
        'amount': double.parse(_amountController.text),
        'type': _type,
        'categoryId': _categoryId,
        'currency': 'USD',
        'date': _date.toIso8601String(),
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        'goalId': _goalId,
        'budgetId': _budgetId,
      });

      if (mounted) {
        HapticFeedback.lightImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_type == 'INCOME' ? 'Income' : 'Expense'} added successfully!'),
                backgroundColor: AppColors.income,
              ),
            );
          }
        });
        
        // Invalidate dashboard and all related lists/stats to show new data
        Future.microtask(() {
          ref.invalidate(dashboardProvider);
          ref.invalidate(budgetsProvider);
          ref.invalidate(budgetStatusProvider);
          ref.invalidate(goalsProvider);
          ref.invalidate(historyStatsProvider);
          ref.invalidate(historyTransactionsProvider);
        });
        
        // Clear focus first
        FocusManager.instance.primaryFocus?.unfocus();
        
        // Navigate away safely using GoRouter's pop
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) context.pop();
        });
        return; 
      }
    } catch (e) {
      String errorMessage = 'Failed to add transaction';
      if (e is DioException) {
        errorMessage = e.response?.data?['error'] ?? e.message ?? errorMessage;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: AppColors.errorLight),
          );
        }
      });
    } finally {
      // Only set state if we are still mounted AND haven't navigated away
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeImpact() async {
    if (_categoryId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and enter an amount first.')),
      );
      return;
    }
    setState(() => _isAnalyzing = true);
    
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.post(ApiConstants.aiSimulate, data: {
        'amount': double.parse(_amountController.text),
        'categoryId': _categoryId,
        'goalId': _goalId,
      });
      setState(() {
        _analysisResult = response.data['data']['analysis'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to analyze impact.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesState = ref.watch(categoriesProvider);

    final List<Category> filteredCategories = _type == 'INCOME' 
        ? categoriesState.incomeCategories 
        : categoriesState.expenseCategories;

    final goalsAsync = ref.watch(goalsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.dividerLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _type = 'EXPENSE'; _categoryId = null; }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'EXPENSE' ? AppColors.expense : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Expense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _type == 'EXPENSE' ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _type = 'INCOME'; _categoryId = null; }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'INCOME' ? AppColors.income : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Income',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _type == 'INCOME' ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount
              AppTextField(
                controller: _amountController,
                label: 'Amount',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.attach_money),
                validator: Validators.amount,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Title
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. Grocery shopping',
                prefixIcon: const Icon(Icons.title),
                validator: (v) => Validators.required(v, 'Title'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Category
              Text('Category', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (categoriesState.isLoading && filteredCategories.isEmpty)
                    ...List.generate(6, (index) => _buildSkeletonCategory(isDark))
                  else if (filteredCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No categories found. Add one to get started!'),
                    )
                  else
                    ...filteredCategories.map((Category cat) {
                      final isSelected = _categoryId == cat.id;
                      return GestureDetector(
                        onTap: () => setState(() => _categoryId = cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.colorValue
                                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
              const SizedBox(height: 16),

              // Date
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text('Date: ${_date.day}/${_date.month}/${_date.year}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),

              // Notes
              AppTextField(
                controller: _notesController,
                label: 'Notes (optional)',
                hint: 'Add any notes',
                maxLines: 3,
                prefixIcon: const Icon(Icons.notes),
              ),
              const SizedBox(height: 32),

              // Related Budget/Goal (Optional)
              if (_type == 'EXPENSE') ...[
                Text('Related Budget (Optional)', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                budgetsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Text('Could not load budgets'),
                  data: (budgets) {
                    final filteredBudgets = _categoryId != null 
                        ? budgets.where((b) => b.categoryId == _categoryId).toList()
                        : budgets;
                    
                    if (filteredBudgets.isEmpty) {
                      return Text(
                        _categoryId == null ? 'Select a category first' : 'No budget for this category',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _budgetId,
                      hint: const Text('Select a budget...'),
                      decoration: _dropdownDecoration(isDark),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('None')),
                        ...filteredBudgets.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text('${b.categoryIcon ?? '💰'} ${b.categoryName ?? 'Budget'}'),
                        )),
                      ],
                      onChanged: (v) => setState(() => _budgetId = v),
                    );
                  },
                ),
              ] else ...[
                Text('Related Goal (Optional)', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                goalsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Text('Could not load goals'),
                  data: (goals) {
                    final activeGoals = goals.where((g) => g.status == GoalStatus.inProgress).toList();
                    if (activeGoals.isEmpty) {
                      return const Text('No active goals available.');
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _goalId,
                      hint: const Text('Select a goal...'),
                      decoration: _dropdownDecoration(isDark),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('None')),
                        ...activeGoals.map((g) => DropdownMenuItem(
                          value: g.id,
                          child: Text('${g.icon ?? '🎯'} ${g.title}'),
                        )),
                      ],
                      onChanged: (v) => setState(() => _goalId = v),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),

              // AI Analysis Button & Result
              if (_type == 'EXPENSE') ...[
                AppButton(
                  text: 'Analyze Impact',
                  onPressed: _analyzeImpact,
                  isLoading: _isAnalyzing,
                  icon: Icons.auto_awesome,
                  isOutlined: true,
                  width: double.infinity,
                ),
                if (_analysisResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome, color: (isDark ? AppColors.primaryDark : AppColors.primaryLight), size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_analysisResult!, style: AppTextStyles.bodyMedium)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],

              // Submit
              AppButton(
                text: 'Add ${_type == 'INCOME' ? 'Income' : 'Expense'}',
                onPressed: _submit,
                isLoading: _isLoading,
                width: double.infinity,
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
    );
  }

  Widget _buildSkeletonCategory(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 16, color: Colors.white),
            const SizedBox(width: 6),
            Container(width: 40, height: 13, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
