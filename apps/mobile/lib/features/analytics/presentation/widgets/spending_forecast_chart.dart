import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/prediction_model.dart';

class SpendingForecastChart extends StatelessWidget {
  final List<ForecastData> data;
  const SpendingForecastChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (data.isEmpty) return const Center(child: Text('No forecast data available'));

    final actualSpots = data
        .asMap()
        .entries
        .where((e) => e.value.actual != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.actual!))
        .toList();

    final forecastSpots = data
        .asMap()
        .entries
        .where((e) => e.value.forecast != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.forecast!))
        .toList();

    // Add the last actual spot to forecast spots to connect the lines
    if (actualSpots.isNotEmpty && forecastSpots.isNotEmpty) {
      forecastSpots.insert(0, actualSpots.last);
    }

    double maxY = 0;
    for (var d in data) {
      final val = (d.actual ?? d.forecast ?? 0);
      if (val > maxY) maxY = val;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 7,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= data.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Day ${value.toInt() + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        CurrencyFormatter.formatCompact(value, 'USD'),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.2,
              lineBarsData: [
                // Actual Spending Line
                LineChartBarData(
                  spots: actualSpots,
                  isCurved: true,
                  color: AppColors.primaryLight,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight.withValues(alpha: 0.3),
                        AppColors.primaryLight.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Forecast Spending Line
                LineChartBarData(
                  spots: forecastSpots,
                  isCurved: true,
                  color: AppColors.expense.withValues(alpha: 0.5),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(AppColors.primaryLight, 'Actual Spending'),
            const SizedBox(width: 24),
            _buildLegend(AppColors.expense.withValues(alpha: 0.5), 'Projected Forecast', isDashed: true),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
