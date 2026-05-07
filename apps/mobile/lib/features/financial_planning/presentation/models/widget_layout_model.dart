enum DashboardWidgetType {
  budgetOverview,
  goalsOverview,
  spendingAnalytics,
  savingsProgress,
  budgetAlerts,
  goalMilestones,
  monthlySummary,
  aiInsights
}

class DashboardWidgetConfig {
  final DashboardWidgetType type;
  final bool isVisible;
  final bool isCollapsed;
  final int order;

  DashboardWidgetConfig({
    required this.type,
    this.isVisible = true,
    this.isCollapsed = false,
    required this.order,
  });

  DashboardWidgetConfig copyWith({
    bool? isVisible,
    bool? isCollapsed,
    int? order,
  }) {
    return DashboardWidgetConfig(
      type: type,
      isVisible: isVisible ?? this.isVisible,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'isVisible': isVisible,
      'isCollapsed': isCollapsed,
      'order': order,
    };
  }

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetConfig(
      type: DashboardWidgetType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => DashboardWidgetType.monthlySummary,
      ),
      isVisible: json['isVisible'] ?? true,
      isCollapsed: json['isCollapsed'] ?? false,
      order: json['order'] ?? 0,
    );
  }

  String get displayName {
    switch (type) {
      case DashboardWidgetType.budgetOverview: return 'Spending Budgets';
      case DashboardWidgetType.goalsOverview: return 'Savings Goals';
      case DashboardWidgetType.spendingAnalytics: return 'Spending Analytics';
      case DashboardWidgetType.savingsProgress: return 'Savings Progress';
      case DashboardWidgetType.budgetAlerts: return 'Budget Alerts';
      case DashboardWidgetType.goalMilestones: return 'Goal Milestones';
      case DashboardWidgetType.monthlySummary: return 'Financial Summary';
      case DashboardWidgetType.aiInsights: return 'AI Insights';
    }
  }
}
