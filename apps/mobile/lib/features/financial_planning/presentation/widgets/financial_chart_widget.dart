import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:smart_finance_ai/features/dashboard/presentation/providers/dashboard_provider.dart';

class FinancialChartWidget extends ConsumerWidget {
  const FinancialChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      data: (data) {
        final expenseBreakdown = (data['categoryBreakdown'] as List?) ?? [];
        if (expenseBreakdown.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No spending data for charts')),
          );
        }

        return Container(
          height: 240,
          padding: const EdgeInsets.all(16),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: expenseBreakdown.take(5).map((cat) {
                final color = _getColorFromString(cat['color'] ?? '');
                return PieChartSectionData(
                  color: color,
                  value: (cat['percentage'] as num).toDouble(),
                  title: '${cat['percentage']}%',
                  radius: 50,
                  titleStyle: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  badgeWidget: _buildBadge(cat['icon'] ?? '💰', color),
                  badgePositionPercentageOffset: 1.1,
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadge(String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(icon, style: const TextStyle(fontSize: 12)),
    );
  }

  Color _getColorFromString(String hex) {
    try {
      if (hex.isEmpty) return AppColors.primary;
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
