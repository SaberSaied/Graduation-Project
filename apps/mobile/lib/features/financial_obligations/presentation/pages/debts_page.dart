import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/obligations_provider.dart';
import '../widgets/debt_progress_card.dart';
import '../widgets/add_obligation_dialog.dart';

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(obligationsProvider('DEBT'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Debts & IOUs'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: debtsAsync.when(
        data: (debts) {
          if (debts.isEmpty) {
            return _buildEmptyState();
          }
          
          final totalRemaining = debts.fold<double>(0, (sum, item) => sum + (item.remainingAmount ?? item.amount));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildTotalDebtHeader(totalRemaining),
              const SizedBox(height: 24),
              ...debts.map((debt) => DebtProgressCard(debt: debt)),
              const SizedBox(height: 32),
              _buildDebtInsightCard(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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

  Widget _buildTotalDebtHeader(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.expense,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.expense.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Debt',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppColors.primaryLight),
              const SizedBox(width: 12),
              Text('Snowball Method', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'AI recommends paying off your "Car Installment" first to clear one obligation quickly and build momentum.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text('No Debts Found', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          const Text('You are debt-free! (or just haven\'t added any)'),
        ],
      ),
    );
  }
}
