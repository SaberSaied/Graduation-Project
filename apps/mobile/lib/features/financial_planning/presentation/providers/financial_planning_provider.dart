import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_finance_ai/features/financial_planning/presentation/models/widget_layout_model.dart';

final financialPlanningProvider = StateNotifierProvider<FinancialPlanningNotifier, List<DashboardWidgetConfig>>((ref) {
  return FinancialPlanningNotifier();
});

class FinancialPlanningNotifier extends StateNotifier<List<DashboardWidgetConfig>> {
  static const String _layoutBoxName = 'financial_planning_layout';
  static const String _layoutKey = 'widget_configs';

  FinancialPlanningNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    final box = await Hive.openBox(_layoutBoxName);
    final savedData = box.get(_layoutKey);

    if (savedData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedData);
        state = decoded.map((item) => DashboardWidgetConfig.fromJson(item)).toList();
        state.sort((a, b) => a.order.compareTo(b.order));
        return;
      } catch (e) {
        // Fallback to default if error decoding
      }
    }

    // Default layout
    state = [
      DashboardWidgetConfig(type: DashboardWidgetType.monthlySummary, order: 0),
      DashboardWidgetConfig(type: DashboardWidgetType.aiInsights, order: 1),
      DashboardWidgetConfig(type: DashboardWidgetType.budgetOverview, order: 2),
      DashboardWidgetConfig(type: DashboardWidgetType.goalsOverview, order: 3),
      DashboardWidgetConfig(type: DashboardWidgetType.spendingAnalytics, order: 4),
      DashboardWidgetConfig(type: DashboardWidgetType.savingsProgress, order: 5),
      DashboardWidgetConfig(type: DashboardWidgetType.budgetAlerts, order: 6),
      DashboardWidgetConfig(type: DashboardWidgetType.goalMilestones, order: 7),
    ];
    _saveLayout();
  }

  void reorderWidgets(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<DashboardWidgetConfig> newList = List.from(state);
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);

    // Update orders
    state = newList.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();

    _saveLayout();
  }

  void toggleVisibility(DashboardWidgetType type) {
    state = state.map((config) {
      if (config.type == type) {
        return config.copyWith(isVisible: !config.isVisible);
      }
      return config;
    }).toList();
    _saveLayout();
  }

  void toggleCollapsed(DashboardWidgetType type) {
    state = state.map((config) {
      if (config.type == type) {
        return config.copyWith(isCollapsed: !config.isCollapsed);
      }
      return config;
    }).toList();
    _saveLayout();
  }

  Future<void> _saveLayout() async {
    final box = await Hive.openBox(_layoutBoxName);
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await box.put(_layoutKey, encoded);
  }

  Future<void> resetLayout() async {
    final box = await Hive.openBox(_layoutBoxName);
    await box.delete(_layoutKey);
    await _init();
  }
}
