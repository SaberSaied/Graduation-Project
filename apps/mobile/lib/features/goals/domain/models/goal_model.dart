enum GoalStatus {
  inProgress,
  completed,
  cancelled
}

enum AutoSaveFrequency {
  daily,
  weekly,
  monthly
}

class Goal {
  final String id;
  final String title;
  final String? description;
  final double targetAmount;
  final double savedAmount;
  final String currency;
  final DateTime? deadline;
  final String? icon;
  final String? color;
  final GoalStatus status;
  final double? autoSaveAmount;
  final double? autoSavePercentage;
  final AutoSaveFrequency? autoSaveFrequency;

  Goal({
    required this.id,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.savedAmount,
    required this.currency,
    this.deadline,
    this.icon,
    this.color,
    required this.status,
    this.autoSaveAmount,
    this.autoSavePercentage,
    this.autoSaveFrequency,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      savedAmount: (json['savedAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      icon: json['icon'],
      color: json['color'],
      status: _parseStatus(json['status']),
      autoSaveAmount: (json['autoSaveAmount'])?.toDouble(),
      autoSavePercentage: (json['autoSavePercentage'])?.toDouble(),
      autoSaveFrequency: _parseFrequency(json['autoSaveFrequency']),
    );
  }

  static GoalStatus _parseStatus(String? status) {
    switch (status) {
      case 'COMPLETED': return GoalStatus.completed;
      case 'CANCELLED': return GoalStatus.cancelled;
      default: return GoalStatus.inProgress;
    }
  }

  static AutoSaveFrequency? _parseFrequency(String? freq) {
    switch (freq) {
      case 'DAILY': return AutoSaveFrequency.daily;
      case 'WEEKLY': return AutoSaveFrequency.weekly;
      case 'MONTHLY': return AutoSaveFrequency.monthly;
      default: return null;
    }
  }

  double get progressPercent => targetAmount > 0 ? savedAmount / targetAmount : 0;
  double get remainingAmount => targetAmount - savedAmount;
  bool get isCompleted => savedAmount >= targetAmount;
}
