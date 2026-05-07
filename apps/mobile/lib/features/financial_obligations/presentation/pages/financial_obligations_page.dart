import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_obligation.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/obligations_provider.dart';
import '../widgets/reminder_banner.dart';
import '../widgets/due_bill_card.dart';
import 'subscriptions_page.dart';
import 'debts_page.dart';
import 'loans_page.dart';
import 'reminders_page.dart';
import '../widgets/add_obligation_dialog.dart';

class FinancialObligationsPage extends ConsumerWidget {
  const FinancialObligationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(obligationsSummaryProvider);
    final upcomingBillsAsync = ref.watch(obligationsProvider('BILL'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Financial Obligations'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(obligationsSummaryProvider);
          ref.invalidate(obligationsProvider(null));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summaryAsync.when(
                data: (summary) => Column(
                  children: [
                    if (summary.overdueCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ReminderBanner(
                          title: 'Overdue Payments Detected',
                          message: 'You have ${summary.overdueCount} overdue obligations that need attention.',
                          color: AppColors.expense,
                          icon: Icons.priority_high_rounded,
                        ),
                      ),
                    
                    _buildQuickSummary(context, summary),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader(context, 'Categories', null),
                    const SizedBox(height: 16),
                    _buildCategoryGrid(context),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Upcoming Bills', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersPage()));
              }),
              const SizedBox(height: 16),
              upcomingBillsAsync.when(
                data: (bills) {
                  if (bills.isEmpty) {
                    return _buildEmptyState(context, 'No upcoming bills');
                  }
                  return Column(
                    children: bills.take(3).map((bill) => DueBillCard(
                      bill: bill,
                      onPayPressed: () {
                        ref.read(obligationActionProvider.notifier).markAsPaid(bill.id, bill.amount);
                      },
                    )).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              
              const SizedBox(height: 32),
              _buildAiInsightsSection(context, summaryAsync),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddObligationDialog(),
          );
        },
        backgroundColor: AppColors.primaryLight,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickSummary(BuildContext context, ObligationsSummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Monthly Bills', '\$${summary.totalMonthlyLiabilities.toStringAsFixed(0)}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildSummaryItem('Total Debt', '\$${summary.totalDebt.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Payment',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
              Text(
                'May 12 (Netflix)',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback? onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCategoryCard(context, 'Subscriptions', Icons.subscriptions_rounded, AppColors.primaryLight, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsPage()));
        }),
        _buildCategoryCard(context, 'Debts', Icons.money_off_rounded, AppColors.expense, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsPage()));
        }),
        _buildCategoryCard(context, 'Loans', Icons.account_balance_rounded, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansPage()));
        }),
        _buildCategoryCard(context, 'Reminders', Icons.notifications_active_rounded, AppColors.income, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersPage()));
        }),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightsSection(BuildContext context, AsyncValue<ObligationsSummary> summaryAsync) {
    return summaryAsync.when(
      data: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text('AI Financial Planner', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...summary.aiInsights.map((insight) => _buildInsightCard(context, insight)),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildInsightCard(BuildContext context, String insight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.grey.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
