class PredictionData {
  final double monthlySpendingForecast;
  final String spendingPaceStatus;
  final double projectedSavings;
  final int financialHealthScore;
  final List<PredictionInsight> insights;
  final List<ForecastData> spendingForecastChart;
  final SavingsProjection savingsProjection;

  PredictionData({
    required this.monthlySpendingForecast,
    required this.spendingPaceStatus,
    required this.projectedSavings,
    required this.financialHealthScore,
    required this.insights,
    required this.spendingForecastChart,
    required this.savingsProjection,
  });

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    return PredictionData(
      monthlySpendingForecast: (json['monthlySpendingForecast'] ?? 0).toDouble(),
      spendingPaceStatus: json['spendingPaceStatus'] ?? 'on_track',
      projectedSavings: (json['projectedSavings'] ?? 0).toDouble(),
      financialHealthScore: (json['financialHealthScore'] ?? 0).toInt(),
      insights: (json['insights'] as List? ?? [])
          .map((i) => PredictionInsight.fromJson(i))
          .toList(),
      spendingForecastChart: (json['spendingForecastChart'] as List? ?? [])
          .map((f) => ForecastData.fromJson(f))
          .toList(),
      savingsProjection: SavingsProjection.fromJson(json['savingsProjection'] ?? {}),
    );
  }
}

class PredictionInsight {
  final String type;
  final String title;
  final String message;
  final String icon;
  final double confidence;

  PredictionInsight({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.confidence,
  });

  factory PredictionInsight.fromJson(Map<String, dynamic> json) {
    return PredictionInsight(
      type: json['type'] ?? 'tip',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      icon: json['icon'] ?? '💡',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

class ForecastData {
  final DateTime date;
  final double? actual;
  final double? forecast;

  ForecastData({
    required this.date,
    this.actual,
    this.forecast,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      date: DateTime.parse(json['date']),
      actual: json['actual']?.toDouble(),
      forecast: json['forecast']?.toDouble(),
    );
  }
}

class SavingsProjection {
  final double currentSavings;
  final double projectedEndMonth;
  final List<GoalCompletionEstimate> goalCompletionEstimates;

  SavingsProjection({
    required this.currentSavings,
    required this.projectedEndMonth,
    required this.goalCompletionEstimates,
  });

  factory SavingsProjection.fromJson(Map<String, dynamic> json) {
    return SavingsProjection(
      currentSavings: (json['currentSavings'] ?? 0).toDouble(),
      projectedEndMonth: (json['projectedEndMonth'] ?? 0).toDouble(),
      goalCompletionEstimates: (json['goalCompletionEstimates'] as List? ?? [])
          .map((g) => GoalCompletionEstimate.fromJson(g))
          .toList(),
    );
  }
}

class GoalCompletionEstimate {
  final String goalId;
  final String title;
  final DateTime estimatedCompletionDate;
  final double confidence;

  GoalCompletionEstimate({
    required this.goalId,
    required this.title,
    required this.estimatedCompletionDate,
    required this.confidence,
  });

  factory GoalCompletionEstimate.fromJson(Map<String, dynamic> json) {
    return GoalCompletionEstimate(
      goalId: json['goalId'] ?? '',
      title: json['title'] ?? '',
      estimatedCompletionDate: DateTime.parse(json['estimatedCompletionDate']),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}
