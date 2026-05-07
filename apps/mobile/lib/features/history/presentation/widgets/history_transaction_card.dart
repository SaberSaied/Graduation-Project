import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class HistoryTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const HistoryTransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = transaction['type'] ?? 'EXPENSE';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final currency = transaction['currency'] ?? 'USD';
    final category = transaction['category'] as Map<String, dynamic>?;
    final isIncome = type == 'INCOME';
    final date = transaction['date'] != null ? DateTime.parse(transaction['date']) : DateTime.now();

    final Color catColor = (() {
      try {
        final hex = category?['color']?.replaceAll('#', '') ?? '';
        if (hex.isEmpty) return isIncome ? AppColors.income : AppColors.expense;
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        return isIncome ? AppColors.income : AppColors.expense;
      }
    })();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        category?['icon'] ?? '💰',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['title'] ?? 'Untitled',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              category?['name'] ?? 'Other',
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(width: 4),
                            const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatTime(date),
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatWithSign(amount, currency, type),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isIncome ? AppColors.income : AppColors.expense,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (transaction['paymentMethod'] != null)
                        Text(
                          transaction['paymentMethod'].toString(),
                          style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
