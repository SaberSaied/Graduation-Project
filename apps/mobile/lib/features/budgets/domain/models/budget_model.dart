enum BudgetPeriod {
  weekly,
  monthly,
  custom
}

class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String currency;
  final BudgetPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final double alertThreshold;
  final String? categoryName;
  final String? categoryIcon;
  final double? spent;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.period,
    this.startDate,
    this.endDate,
    this.alertThreshold = 0.8,
    this.categoryName,
    this.categoryIcon,
    this.spent,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['userId'],
      categoryId: json['categoryId'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      period: _parsePeriod(json['period']),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      alertThreshold: (json['alertThreshold'] ?? 0.8).toDouble(),
      categoryName: json['categoryName'] ?? json['category']?['name'],
      categoryIcon: json['categoryIcon'] ?? json['category']?['icon'],
      spent: (json['spent'] ?? 0).toDouble(),
    );
  }

  static BudgetPeriod _parsePeriod(String? period) {
    switch (period) {
      case 'WEEKLY': return BudgetPeriod.weekly;
      case 'CUSTOM': return BudgetPeriod.custom;
      default: return BudgetPeriod.monthly;
    }
  }

  double get usagePercent => amount > 0 ? (spent ?? 0) / amount : 0;
  bool get isOverBudget => usagePercent >= 1.0;
  bool get isNearLimit => usagePercent >= alertThreshold;
}
