import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';

final analyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final responses = await Future.wait([
    client.get(ApiConstants.analyticsTopCategories),
    client.get(ApiConstants.analyticsTrends),
    client.get(ApiConstants.analyticsInsights),
  ]);
  return {
    'topCategories': responses[0].data['data'],
    'trends': responses[1].data['data'],
    'insights': responses[2].data['data'],
  };
});

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(analyticsProvider),
        child: analyticsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => AppErrorWidget(message: 'Failed to load analytics', onRetry: () => ref.invalidate(analyticsProvider)),
          data: (data) {
            final topCategories = List<Map<String, dynamic>>.from(data['topCategories'] ?? []);
            final trends = List<Map<String, dynamic>>.from(data['trends'] ?? []);
            final insights = List<Map<String, dynamic>>.from(data['insights'] ?? []);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPredictionsEntryCard(context, isDark),
                const SizedBox(height: 32),
                _buildAIRecommendations(insights, isDark),
                const SizedBox(height: 32),
                Text('Spending Trends', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                    child: SizedBox(
                      height: 250,
                      child: _buildBarChart(trends, isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Top Categories (This Month)', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                if (topCategories.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No expenses this month')))
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: topCategories.map((c) {
                          final color = (() {
                            try {
                              final colorCode = c['color']?.replaceAll('#', '') ?? '4F6EF5';
                              return Color(int.parse('0xFF$colorCode', radix: 16));
                            } catch (_) {
                              return AppColors.primaryLight;
                            }
                          })();
                          final total = (c['total'] ?? 0).toDouble();
                          final percent = (c['percentage'] ?? 0).toInt();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Text(c['icon'] ?? '📦', style: const TextStyle(fontSize: 20)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(c['name'] ?? '', style: AppTextStyles.titleMedium),
                                          Text(CurrencyFormatter.format(total, 'USD'), style: AppTextStyles.titleMedium),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: percent / 100,
                                              backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                                              color: color,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text('$percent%', style: AppTextStyles.labelSmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAIRecommendations(List<Map<String, dynamic>> insights, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Recommendations by AI', style: AppTextStyles.headlineSmall),
          ],
        ),
        const SizedBox(height: 16),
        if (insights.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('AI is analyzing your data...')),
            ),
          )
        else
          ...insights.map((insight) {
            final type = insight['type'] ?? 'tip';
            final color = type == 'warning' 
                ? AppColors.expense 
                : (type == 'achievement' ? AppColors.income : (isDark ? AppColors.primaryDark : AppColors.primaryLight));

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.05),
                      isDark ? Colors.transparent : Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(insight['icon'] ?? '💡', style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight['title'] ?? '',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              insight['message'] ?? '',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPredictionsEntryCard(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => context.push('/analytics/predictions'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight,
              AppColors.primaryLight.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Predictions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Forecast your spending, track health score, and get AI insights.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> trends, bool isDark) {
    if (trends.isEmpty) return const Center(child: Text('Not enough data'));

    double maxY = 0;
    for (var t in trends) {
      final double expense = (t['expenses'] ?? 0).toDouble();
      if (expense > maxY) maxY = expense;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= trends.length) return const SizedBox();
                final label = trends[value.toInt()]['label']?.toString() ?? '';
                final parts = label.split(' ');
                final shortLabel = parts.isNotEmpty ? parts[0] : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(shortLabel, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  CurrencyFormatter.formatCompact(value, 'USD'),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: trends.asMap().entries.map((e) {
          final index = e.key;
          final expense = (e.value['expenses'] ?? 0).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: expense,
                color: AppColors.expense,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
