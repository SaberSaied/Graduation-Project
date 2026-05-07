import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../domain/models/prediction_model.dart';
import '../widgets/financial_health_score.dart';
import '../widgets/spending_forecast_chart.dart';
import '../widgets/ai_prediction_card.dart';
import '../widgets/savings_projection_widget.dart';

final predictionsProvider = FutureProvider.autoDispose<PredictionData>((ref) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get(ApiConstants.predictions);
  return PredictionData.fromJson(response.data['data']);
});

class PredictionsPage extends ConsumerWidget {
  const PredictionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(predictionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('AI Predictions', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: predictionsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(50), child: LoadingIndicator())),
              error: (e, _) => AppErrorWidget(
                message: 'Failed to load AI predictions',
                onRetry: () => ref.invalidate(predictionsProvider),
              ),
              data: (data) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Financial Health Score Section
                    Center(
                      child: FinancialHealthScore(score: data.financialHealthScore),
                    ),
                    const SizedBox(height: 32),
                    
                    // AI Insights
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Text('AI Spending Insights', style: AppTextStyles.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...data.insights.map((insight) => AiPredictionCard(insight: insight)),
                    
                    const SizedBox(height: 32),
                    
                    // Spending Forecast Chart
                    Text('Spending Forecast', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Predicted end of month: \$${data.monthlySpendingForecast.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 0,
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SpendingForecastChart(data: data.spendingForecastChart),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Savings & Goals Projection
                    Text('Savings & Goal Projections', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 16),
                    SavingsProjectionWidget(projection: data.savingsProjection),
                    
                    const SizedBox(height: 50), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
