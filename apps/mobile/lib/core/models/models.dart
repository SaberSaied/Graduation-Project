class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String type;
  final bool isDefault;
  final String? userId;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    this.userId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      type: json['type'],
      isDefault: json['isDefault'] ?? false,
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'isDefault': isDefault,
      'userId': userId,
    };
  }
}

class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String currency;
  final int month;
  final int year;
  final String? categoryName;
  final String? categoryIcon;
  final double? spent;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.month,
    required this.year,
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
      month: json['month'],
      year: json['year'],
      categoryName: json['categoryName'] ?? json['category']?['name'],
      categoryIcon: json['categoryIcon'] ?? json['category']?['icon'],
      spent: (json['spent'] ?? 0).toDouble(),
    );
  }
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
  final String status;

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
      status: json['status'] ?? 'IN_PROGRESS',
    );
  }
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final String currency;
  final String? financialGoal;
  final String? image;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.currency,
    this.financialGoal,
    this.image,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      currency: json['currency'] ?? 'USD',
      financialGoal: json['financialGoal'],
      image: json['image'],
    );
  }
}
