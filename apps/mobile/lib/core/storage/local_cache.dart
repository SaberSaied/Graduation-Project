import 'package:hive_flutter/hive_flutter.dart';

class LocalCache {
  static const String _dashboardBox = 'dashboard_cache';
  static const String _categoriesBox = 'categories_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_dashboardBox);
    await Hive.openBox(_categoriesBox);
  }

  // Dashboard cache
  static Box get dashboardBox => Hive.box(_dashboardBox);

  static Future<void> cacheDashboard(Map<String, dynamic> data) async {
    await dashboardBox.put('data', data);
    await dashboardBox.put('cachedAt', DateTime.now().toIso8601String());
  }

  static Map<String, dynamic>? getCachedDashboard() {
    final data = dashboardBox.get('data');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // Categories cache
  static Box get categoriesBox => Hive.box(_categoriesBox);

  static Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    await categoriesBox.put('data', categories);
  }

  static List<Map<String, dynamic>>? getCachedCategories() {
    final data = categoriesBox.get('data');
    if (data == null) return null;
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<void> clearAll() async {
    await dashboardBox.clear();
    await categoriesBox.clear();
  }
}
