import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/history_filter_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class HistoryFiltersSheet extends ConsumerStatefulWidget {
  final HistoryFilter initialFilter;

  const HistoryFiltersSheet({super.key, required this.initialFilter});

  @override
  ConsumerState<HistoryFiltersSheet> createState() => _HistoryFiltersSheetState();
}

class _HistoryFiltersSheetState extends ConsumerState<HistoryFiltersSheet> {
  late HistoryFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Advanced Filters', style: AppTextStyles.titleLarge),
              TextButton(
                onPressed: () => setState(() => _currentFilter = HistoryFilter()),
                child: const Text('Reset All'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Date Range Section
          _buildSectionTitle('Date Range'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HistoryDateRange.values.map((range) {
                final isSelected = _currentFilter.dateRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getDateRangeLabel(range)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (range == HistoryDateRange.custom) {
                        _showCustomDateRangePicker();
                      } else {
                        setState(() => _currentFilter = _currentFilter.copyWith(dateRange: range));
                      }
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Categories Section
          _buildSectionTitle('Categories'),
          const SizedBox(height: 12),
          if (categoriesState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (categoriesState.error != null)
            Text('Error: ${categoriesState.error}')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [...categoriesState.incomeCategories, ...categoriesState.expenseCategories].map((cat) {
                final isSelected = _currentFilter.categoryIds.contains(cat.id);
                return FilterChip(
                  avatar: Text(cat.icon),
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (val) {
                    final newIds = List<String>.from(_currentFilter.categoryIds);
                    if (val) {
                      newIds.add(cat.id);
                    } else {
                      newIds.remove(cat.id);
                    }
                    setState(() => _currentFilter = _currentFilter.copyWith(categoryIds: newIds));
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Amount Range
          _buildSectionTitle('Amount Range'),
          const SizedBox(height: 12),
          RangeSlider(
            values: RangeValues(
              _currentFilter.minAmount ?? 0,
              _currentFilter.maxAmount ?? 10000,
            ),
            min: 0,
            max: 10000,
            divisions: 20,
            labels: RangeLabels(
              '\$${(_currentFilter.minAmount ?? 0).toInt()}',
              '\$${(_currentFilter.maxAmount ?? 10000).toInt()}',
            ),
            onChanged: (values) {
              setState(() => _currentFilter = _currentFilter.copyWith(
                minAmount: values.start,
                maxAmount: values.end,
              ));
            },
          ),
          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _currentFilter),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  String _getDateRangeLabel(HistoryDateRange range) {
    switch (range) {
      case HistoryDateRange.today: return 'Today';
      case HistoryDateRange.yesterday: return 'Yesterday';
      case HistoryDateRange.thisWeek: return 'This Week';
      case HistoryDateRange.thisMonth: return 'This Month';
      case HistoryDateRange.lastMonth: return 'Last Month';
      case HistoryDateRange.last3Months: return 'Last 3 Months';
      case HistoryDateRange.thisYear: return 'This Year';
      case HistoryDateRange.custom: return 'Custom Range';
    }
  }

  Future<void> _showCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _currentFilter.startDate != null && _currentFilter.endDate != null
        ? DateTimeRange(start: _currentFilter.startDate!, end: _currentFilter.endDate!)
        : null,
    );

    if (picked != null) {
      setState(() => _currentFilter = _currentFilter.copyWith(
        dateRange: HistoryDateRange.custom,
        startDate: picked.start,
        endDate: picked.end,
      ));
    }
  }
}
