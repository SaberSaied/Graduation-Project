import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:finance_manager/features/financial_planning/presentation/models/widget_layout_model.dart';
import 'package:finance_manager/features/financial_planning/presentation/providers/financial_planning_provider.dart';
import '../widgets/draggable_dashboard_card.dart';
import '../widgets/monthly_summary_widget.dart';
import '../widgets/budget_summary_widget.dart';
import '../widgets/goals_summary_widget.dart';
import '../widgets/insights_widget.dart';
import '../widgets/unified_add_dialog.dart';
import '../widgets/financial_chart_widget.dart';
import 'package:go_router/go_router.dart';

class FinancialPlanningPage extends ConsumerWidget {
  const FinancialPlanningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetConfigs = ref.watch(financialPlanningProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Financial Planning',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const UnifiedAddDialog(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => ref.read(financialPlanningProvider.notifier).resetLayout(),
            ),
          ],
        ),
        
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverReorderableList(
            itemCount: widgetConfigs.length,
            itemBuilder: (context, index) {
              final config = widgetConfigs[index];
              if (!config.isVisible) return const SizedBox.shrink(key: ValueKey('hidden'));

              return ReorderableDelayedDragStartListener(
                key: ValueKey(config.type),
                index: index,
                child: _buildWidgetByType(context, config, ref),
              );
            },
            onReorder: (oldIndex, newIndex) {
              ref.read(financialPlanningProvider.notifier).reorderWidgets(oldIndex, newIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetByType(BuildContext context, DashboardWidgetConfig config, WidgetRef ref) {
    final notifier = ref.read(financialPlanningProvider.notifier);

    switch (config.type) {
      case DashboardWidgetType.monthlySummary:
        return DraggableDashboardCard(
          title: 'Financial Summary',
          isCollapsed: config.isCollapsed,
          onToggleCollapse: () => notifier.toggleCollapsed(config.type),
          onActionTap: () => context.push('/transactions'),
          accentColor: AppColors.primary,
          child: const MonthlySummaryWidget(),
        );
      case DashboardWidgetType.aiInsights:
        return DraggableDashboardCard(
          title: 'AI Insights',
          isCollapsed: config.isCollapsed,
          onToggleCollapse: () => notifier.toggleCollapsed(config.type),
          onActionTap: () => context.push('/analytics'),
          accentColor: Colors.purpleAccent,
          child: const InsightsWidget(),
        );
      case DashboardWidgetType.budgetOverview:
        return DraggableDashboardCard(
          title: 'Spending Budgets',
          isCollapsed: config.isCollapsed,
          onToggleCollapse: () => notifier.toggleCollapsed(config.type),
          onActionTap: () => context.push('/budgets'),
          accentColor: AppColors.expense,
          child: const BudgetSummaryWidget(),
        );
      case DashboardWidgetType.goalsOverview:
        return DraggableDashboardCard(
          title: 'Savings Goals',
          isCollapsed: config.isCollapsed,
          onToggleCollapse: () => notifier.toggleCollapsed(config.type),
          onActionTap: () => context.push('/goals'),
          accentColor: AppColors.income,
          child: const GoalsSummaryWidget(),
        );
      case DashboardWidgetType.spendingAnalytics:
        return DraggableDashboardCard(
          title: 'Spending Analytics',
          isCollapsed: config.isCollapsed,
          onToggleCollapse: () => notifier.toggleCollapsed(config.type),
          accentColor: Colors.blueAccent,
          child: const FinancialChartWidget(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
