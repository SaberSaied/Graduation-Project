import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../domain/models/budget_model.dart';
import '../providers/budgets_provider.dart';
import '../widgets/budget_dialog.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.backgroundDark 
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Spending Control'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _showAnalytics(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showBudgetDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(budgetsProvider);
          ref.invalidate(budgetAnalyticsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _SpendingOverviewCard(budgetsAsync: budgetsAsync),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Active Budgets', style: AppTextStyles.titleLarge),
              ),
            ),
            budgetsAsync.when(
              loading: () => const SliverFillRemaining(child: LoadingIndicator()),
              error: (e, _) => SliverFillRemaining(
                child: AppErrorWidget(
                  message: 'Failed to load budgets',
                  onRetry: () => ref.invalidate(budgetsProvider),
                ),
              ),
              data: (budgets) {
                if (budgets.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No Active Budgets',
                      subtitle: 'Set a limit to control your spending',
                      actionLabel: 'Set First Budget',
                      onAction: () => _showBudgetDialog(context, ref),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _BudgetCard(budget: budgets[index]),
                      childCount: budgets.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref, [Budget? budget]) {
    showDialog(
      context: context,
      builder: (context) => BudgetDialog(budget: budget),
    );
  }

  void _showAnalytics(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _BudgetAnalyticsSheet(),
    );
  }
}

class _SpendingOverviewCard extends StatelessWidget {
  final AsyncValue<List<Budget>> budgetsAsync;

  const _SpendingOverviewCard({required this.budgetsAsync});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.expenseGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.expense.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Spending Limit', 
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              const Icon(Icons.info_outline, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          budgetsAsync.when(
            data: (budgets) {
              final totalLimit = budgets.fold(0.0, (sum, b) => sum + b.amount);
              final totalSpent = budgets.fold(0.0, (sum, b) => sum + (b.spent ?? 0));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(CurrencyFormatter.format(totalLimit, 'USD'), 
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MiniStat(label: 'Spent', value: CurrencyFormatter.format(totalSpent, 'USD')),
                      _MiniStat(label: 'Remaining', value: CurrencyFormatter.format(totalLimit - totalSpent, 'USD')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Colors.white))),
            error: (_, _) => const Text('Error', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final Budget budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usage = budget.usagePercent;
    final isNearLimit = budget.isNearLimit;
    final isOver = budget.isOverBudget;

    Color progressColor = AppColors.expense;
    if (usage < 0.5) {
      progressColor = Colors.green;
    } else if (usage < budget.alertThreshold) {
      progressColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showOptions(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: progressColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(budget.categoryIcon ?? '📁', style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(budget.categoryName ?? 'Category', style: AppTextStyles.titleMedium),
                          Text(budget.period.name.toLowerCase(), style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(CurrencyFormatter.format(budget.amount, budget.currency), 
                            style: AppTextStyles.titleMedium),
                        Text('Limit', style: AppTextStyles.labelSmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Spent: ${CurrencyFormatter.format(budget.spent ?? 0, budget.currency)}', 
                        style: AppTextStyles.bodySmall),
                    Text('${(usage * 100).toInt()}%', 
                        style: TextStyle(
                          color: progressColor, 
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: usage.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                if (isNearLimit || isOver) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: progressColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        isOver ? 'Over budget!' : 'Nearing limit!',
                        style: TextStyle(color: progressColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Budget'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (ctx) => BudgetDialog(budget: budget));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Budget', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to remove this budget?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(budgetActionProvider.notifier).deleteBudget(budget.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BudgetAnalyticsSheet extends ConsumerWidget {
  const _BudgetAnalyticsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(budgetAnalyticsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Spending Analytics', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          Text('Your top spending categories over the last 3 months', style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),
          analyticsAsync.when(
            data: (data) {
              final List topCategories = data['topCategories'] ?? [];
              if (topCategories.isEmpty) {
                return const Center(child: Text('No spending data yet.'));
              }
              return Column(
                children: topCategories.map<Widget>((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(cat['name'])),
                        Text(CurrencyFormatter.format(cat['amount'].toDouble(), 'USD'), 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Failed to load analytics')),
          ),
        ],
      ),
    );
  }
}
