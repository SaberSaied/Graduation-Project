import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/financial_obligation.dart';
import 'package:intl/intl.dart';

class SubscriptionCard extends StatelessWidget {
  final FinancialObligation subscription;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getSubscriptionColor(subscription.title);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Icon(
                    _getSubscriptionIcon(subscription.title),
                    color: color,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.title,
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.isRecurring ? 'Auto-renews ${subscription.recurringType?.toLowerCase()}' : 'One-time bill',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${subscription.amount.toStringAsFixed(2)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subscription.dueDate != null 
                      ? 'Due ${DateFormat('MMM dd').format(subscription.dueDate!)}'
                      : 'No due date',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getStatusColor(subscription.status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubscriptionColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('netflix')) return Colors.red;
    if (lower.contains('spotify')) return Colors.green;
    if (lower.contains('apple')) return Colors.grey;
    if (lower.contains('google')) return Colors.blue;
    if (lower.contains('amazon')) return Colors.orange;
    if (lower.contains('disney')) return Colors.blue.shade900;
    return AppColors.primaryLight;
  }

  IconData _getSubscriptionIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('netflix')) return Icons.movie;
    if (lower.contains('spotify')) return Icons.music_note;
    if (lower.contains('apple')) return Icons.apple;
    if (lower.contains('google')) return Icons.play_arrow;
    if (lower.contains('amazon')) return Icons.shopping_bag;
    return Icons.subscriptions;
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
