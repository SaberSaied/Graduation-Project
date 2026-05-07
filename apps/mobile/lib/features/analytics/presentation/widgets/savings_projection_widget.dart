import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/prediction_model.dart';

class SavingsProjectionWidget extends StatelessWidget {
  final SavingsProjection projection;
  const SavingsProjectionWidget({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProjectionItem(
                  'Current Savings',
                  CurrencyFormatter.format(projection.currentSavings, 'USD'),
                  AppColors.income,
                ),
                Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
                _buildProjectionItem(
                  'Projected EOM',
                  CurrencyFormatter.format(projection.projectedEndMonth, 'USD'),
                  projection.projectedEndMonth >= projection.currentSavings ? Colors.greenAccent : Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Goal Completion Estimates', style: AppTextStyles.titleMedium),
        const SizedBox(height: 16),
        if (projection.goalCompletionEstimates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No active goals tracking.')),
          )
        else
          ...projection.goalCompletionEstimates.map((g) => _buildGoalEstimateItem(g, isDark)),
      ],
    );
  }

  Widget _buildProjectionItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildGoalEstimateItem(GoalCompletionEstimate goal, bool isDark) {
    final dateStr = DateFormat('MMM yyyy').format(goal.estimatedCompletionDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flag, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Estimated: $dateStr',
                  style: TextStyle(fontSize: 14, color: Colors.blueAccent.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(goal.confidence * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('Confidence', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
