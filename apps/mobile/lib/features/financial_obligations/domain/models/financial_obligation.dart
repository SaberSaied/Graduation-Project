class FinancialObligation {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final ObligationType type;
  final ObligationStatus status;
  final DateTime? dueDate;
  final bool isRecurring;
  final String? recurringType;
  final DateTime startDate;
  final DateTime? endDate;
  final bool? autoRenew;
  final double? totalAmount;
  final double? remainingAmount;
  final double? interestRate;
  final String? lenderInfo;

  FinancialObligation({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.dueDate,
    required this.isRecurring,
    this.recurringType,
    required this.startDate,
    this.endDate,
    this.autoRenew,
    this.totalAmount,
    this.remainingAmount,
    this.interestRate,
    this.lenderInfo,
  });

  factory FinancialObligation.fromJson(Map<String, dynamic> json) {
    return FinancialObligation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      type: _parseType(json['type']),
      status: _parseStatus(json['status']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isRecurring: json['isRecurring'] ?? false,
      recurringType: json['recurringType'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      autoRenew: json['autoRenew'],
      totalAmount: json['totalAmount']?.toDouble(),
      remainingAmount: json['remainingAmount']?.toDouble(),
      interestRate: json['interestRate']?.toDouble(),
      lenderInfo: json['lenderInfo'],
    );
  }

  static ObligationType _parseType(String? type) {
    switch (type) {
      case 'SUBSCRIPTION': return ObligationType.subscription;
      case 'BILL': return ObligationType.bill;
      case 'DEBT': return ObligationType.debt;
      case 'LOAN': return ObligationType.loan;
      case 'INSTALLMENT': return ObligationType.installment;
      default: return ObligationType.bill;
    }
  }

  static ObligationStatus _parseStatus(String? status) {
    switch (status) {
      case 'PAID': return ObligationStatus.paid;
      case 'UPCOMING': return ObligationStatus.upcoming;
      case 'OVERDUE': return ObligationStatus.overdue;
      case 'PAUSED': return ObligationStatus.paused;
      default: return ObligationStatus.upcoming;
    }
  }
}

enum ObligationType { subscription, bill, debt, loan, installment }
enum ObligationStatus { paid, upcoming, overdue, paused }

class ObligationsSummary {
  final double totalMonthlyLiabilities;
  final double totalDebt;
  final int upcomingBillsCount;
  final int overdueCount;
  final List<String> aiInsights;

  ObligationsSummary({
    required this.totalMonthlyLiabilities,
    required this.totalDebt,
    required this.upcomingBillsCount,
    required this.overdueCount,
    required this.aiInsights,
  });

  factory ObligationsSummary.fromJson(Map<String, dynamic> json) {
    return ObligationsSummary(
      totalMonthlyLiabilities: (json['totalMonthlyLiabilities'] ?? 0).toDouble(),
      totalDebt: (json['totalDebt'] ?? 0).toDouble(),
      upcomingBillsCount: (json['upcomingBillsCount'] ?? 0).toInt(),
      overdueCount: (json['overdueCount'] ?? 0).toInt(),
      aiInsights: List<String>.from(json['aiInsights'] ?? []),
    );
  }
}
