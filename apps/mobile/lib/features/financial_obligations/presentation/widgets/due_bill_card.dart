import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/financial_obligation.dart';
import 'package:intl/intl.dart';

class DueBillCard extends StatelessWidget {
  final FinancialObligation bill;
  final VoidCallback? onPayPressed;

  const DueBillCard({
    super.key,
    required this.bill,
    this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isOverdue = bill.status == ObligationStatus.overdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: isOverdue ? Border.all(color: AppColors.expense.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isOverdue ? AppColors.expense : AppColors.primaryLight).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOverdue ? Icons.warning_rounded : Icons.receipt_long_rounded,
                color: isOverdue ? AppColors.expense : AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bill.dueDate != null 
                      ? '${isOverdue ? "Overdue since" : "Due"} ${DateFormat('MMM dd, yyyy').format(bill.dueDate!)}'
                      : 'Recurring Bill',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isOverdue ? AppColors.expense : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${bill.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (bill.status != ObligationStatus.paid)
                  ElevatedButton(
                    onPressed: onPayPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOverdue ? AppColors.expense : AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                else
                  const Icon(Icons.check_circle, color: AppColors.income),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
