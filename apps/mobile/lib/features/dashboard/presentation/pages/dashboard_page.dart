import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get(ApiConstants.analyticsDashboard);
  return response.data['data'] as Map<String, dynamic>;
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: dashboardAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading dashboard...'),
          error: (e, _) => AppErrorWidget(
            message: 'Failed to load dashboard',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (data) => _DashboardContent(data: data, isDark: isDark),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _DashboardContent({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final balance = (data['balance'] ?? 0).toDouble();
    final totalIncome = (data['totalIncome'] ?? 0).toDouble();
    final totalExpenses = (data['totalExpenses'] ?? 0).toDouble();
    final savingsRate = (data['savingsRate'] ?? 0).toInt();
    final recentTx = List<Map<String, dynamic>>.from(data['recentTransactions'] ?? []);
    final budgetAlerts = List<Map<String, dynamic>>.from(data['budgetAlerts'] ?? []);
    final currency = 'USD'; // TODO: get from user profile

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Balance', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(balance, currency),
                style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Income',
                      value: CurrencyFormatter.formatCompact(totalIncome, currency),
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.greenAccent,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: _MiniStat(
                      label: 'Expenses',
                      value: CurrencyFormatter.formatCompact(totalExpenses, currency),
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: _MiniStat(
                      label: 'Saved',
                      value: '$savingsRate%',
                      icon: Icons.savings_rounded,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Budget Alerts
        if (budgetAlerts.isNotEmpty) ...[
          Text('Budget Alerts', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          ...budgetAlerts.map((alert) => _BudgetAlertCard(alert: alert, isDark: isDark)),
          const SizedBox(height: 24),
        ],

        // Recent Transactions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: AppTextStyles.headlineSmall),
            TextButton(
              onPressed: () => GoRouter.of(context).go('/transactions'),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentTx.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('No transactions yet', textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Tap + to add your first transaction', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          )
        else
          ...recentTx.map((tx) => _TransactionTile(tx: tx, isDark: isDark)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: Colors.white60)),
      ],
    );
  }
}

class _BudgetAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final bool isDark;

  const _BudgetAlertCard({required this.alert, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final usage = (alert['usagePercent'] ?? 0).toInt();
    final isOver = usage >= 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(alert['categoryIcon'] ?? '📦', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert['category'] ?? '', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (usage / 100).clamp(0.0, 1.0),
                    backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    color: isOver ? AppColors.errorLight : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$usage%',
              style: AppTextStyles.titleMedium.copyWith(
                color: isOver ? AppColors.errorLight : AppColors.warningLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final bool isDark;

  const _TransactionTile({required this.tx, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final type = tx['type'] ?? 'EXPENSE';
    final amount = (tx['amount'] ?? 0).toDouble();
    final currency = tx['currency'] ?? 'USD';
    final category = tx['category'] as Map<String, dynamic>?;
    final isIncome = type == 'INCOME';

    final Color catColor = (() {
      try {
        final hex = category?['color']?.replaceAll('#', '') ?? '';
        if (hex.isEmpty) return isIncome ? AppColors.income : AppColors.expense;
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return isIncome ? AppColors.income : AppColors.expense;
      }
    })();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(category?['icon'] ?? '📦', style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(tx['title'] ?? '', style: AppTextStyles.titleMedium),
        subtitle: Text(
          tx['date'] != null ? DateFormatter.formatRelative(DateTime.parse(tx['date'])) : '',
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
        ),
        trailing: Text(
          CurrencyFormatter.formatWithSign(amount, currency, type),
          style: AppTextStyles.amountSmall.copyWith(
            color: isIncome ? AppColors.income : AppColors.expense,
          ),
        ),
      ),
    );
  }
}
