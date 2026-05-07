import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/history_provider.dart';
import '../widgets/history_transaction_card.dart';
import '../widgets/history_analytics_header.dart';
import '../widgets/history_filters_sheet.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../domain/models/history_filter_model.dart';
import '../../../../core/utils/date_formatter.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyTransactionsProvider.notifier).fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyTransactionsProvider);
    final filter = ref.watch(historyFilterProvider);
    final statsAsync = ref.watch(historyStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header: Search & Filters summary
            _buildHeader(context, ref, filter),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(historyStatsProvider);
                  return ref.read(historyTransactionsProvider.notifier).fetchTransactions(refresh: true);
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Analytics Summary
                    SliverToBoxAdapter(
                      child: statsAsync.when(
                        data: (stats) => HistoryAnalyticsHeader(
                          totalIncome: (stats['data']['totalIncome'] as num).toDouble(),
                          totalExpenses: (stats['data']['totalExpenses'] as num).toDouble(),
                          balance: (stats['data']['netBalance'] as num).toDouble(),
                          count: (stats['data']['transactionCount'] as num).toInt(),
                        ),
                        loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),

                    // Quick Filter Chips
                    SliverToBoxAdapter(
                      child: _buildQuickFilters(ref, filter),
                    ),

                    // Transaction List
                    if (state.isLoading && state.transactions.isEmpty)
                      const SliverFillRemaining(child: LoadingIndicator())
                    else if (state.transactions.isEmpty)
                      const SliverFillRemaining(
                        child: EmptyStateWidget(
                          icon: Icons.history_rounded,
                          title: 'No transactions found',
                          subtitle: 'Try adjusting your filters or search terms',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == state.transactions.length) {
                                return state.isLoadMore
                                    ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                                    : const SizedBox.shrink();
                              }

                              final tx = state.transactions[index];
                              final date = DateTime.parse(tx['date']);
                              
                              // Grouping by date (Simplified)
                              bool showHeader = false;
                              if (index == 0) {
                                showHeader = true;
                              } else {
                                final prevTx = state.transactions[index - 1];
                                final prevDate = DateTime.parse(prevTx['date']);
                                if (date.day != prevDate.day || date.month != prevDate.month || date.year != prevDate.year) {
                                  showHeader = true;
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showHeader)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
                                      child: Text(
                                        DateFormatter.formatDate(date),
                                        style: AppTextStyles.labelMedium.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  HistoryTransactionCard(
                                    transaction: tx,
                                    onTap: () {
                                      // Show details or edit
                                    },
                                  ),
                                ],
                              );
                            },
                            childCount: state.transactions.length + 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newFilter = await showModalBottomSheet<HistoryFilter>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => HistoryFiltersSheet(initialFilter: filter),
          );
          if (newFilter != null) {
            ref.read(historyFilterProvider.notifier).state = newFilter;
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.tune_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, HistoryFilter filter) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      // Debounced search logic could be here
                      ref.read(historyFilterProvider.notifier).state = filter.copyWith(search: val);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: IconButton(
                  icon: Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
                  onPressed: () {
                    // Quick calendar view
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(WidgetRef ref, HistoryFilter filter) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _QuickChip(
            label: 'All',
            isSelected: filter.type == 'ALL',
            onTap: () => ref.read(historyFilterProvider.notifier).state = filter.copyWith(type: 'ALL'),
          ),
          _QuickChip(
            label: 'Income',
            isSelected: filter.type == 'INCOME',
            onTap: () => ref.read(historyFilterProvider.notifier).state = filter.copyWith(type: 'INCOME'),
            color: AppColors.income,
          ),
          _QuickChip(
            label: 'Expense',
            isSelected: filter.type == 'EXPENSE',
            onTap: () => ref.read(historyFilterProvider.notifier).state = filter.copyWith(type: 'EXPENSE'),
            color: AppColors.expense,
          ),
          const VerticalDivider(width: 24, indent: 8, endIndent: 8),
          _QuickChip(
            label: 'This Month',
            isSelected: filter.dateRange == HistoryDateRange.thisMonth,
            onTap: () => ref.read(historyFilterProvider.notifier).state = filter.copyWith(dateRange: HistoryDateRange.thisMonth),
          ),
          _QuickChip(
            label: 'This Week',
            isSelected: filter.dateRange == HistoryDateRange.thisWeek,
            onTap: () => ref.read(historyFilterProvider.notifier).state = filter.copyWith(dateRange: HistoryDateRange.thisWeek),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _QuickChip({required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: activeColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? activeColor : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.2)),
        ),
        showCheckmark: false,
      ),
    );
  }
}
