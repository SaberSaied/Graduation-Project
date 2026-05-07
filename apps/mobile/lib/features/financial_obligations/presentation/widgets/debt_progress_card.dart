import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/financial_obligation.dart';

class DebtProgressCard extends StatelessWidget {
  final FinancialObligation debt;
  final VoidCallback? onTap;

  const DebtProgressCard({
    super.key,
    required this.debt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double total = debt.totalAmount ?? debt.amount;
    final double remaining = debt.remainingAmount ?? debt.amount;
    final double paid = total - remaining;
    final double progress = total > 0 ? paid / total : 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.title,
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      debt.lenderInfo ?? 'Personal Debt',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(debt.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    debt.status.name.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _getStatusColor(debt.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  '\$${remaining.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.8 ? AppColors.income : AppColors.primaryLight,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% Paid',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
                Text(
                  'Total: \$${total.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ObligationStatus status) {
    switch (status) {
      case ObligationStatus.paid: return AppColors.income;
      case ObligationStatus.overdue: return AppColors.expense;
      case ObligationStatus.paused: return Colors.grey;
      case ObligationStatus.upcoming: return AppColors.warningLight;
    }
  }
}
