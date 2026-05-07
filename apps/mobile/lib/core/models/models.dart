export '../../features/categories/domain/models/category_model.dart';
export '../../features/budgets/domain/models/budget_model.dart';
export '../../features/goals/domain/models/goal_model.dart';

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
