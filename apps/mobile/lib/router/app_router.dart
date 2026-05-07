import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/transactions/presentation/pages/add_transaction_page.dart';
import '../features/ai_chat/presentation/pages/chat_page.dart';
import '../features/goals/presentation/pages/goals_page.dart';
import '../features/goals/presentation/pages/goal_detail_page.dart';
import '../features/budgets/presentation/pages/budgets_page.dart';
import '../features/analytics/presentation/pages/analytics_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/categories_page.dart';
import '../features/settings/presentation/pages/account_details_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/financial_planning/presentation/pages/financial_planning_page.dart';
import '../features/analytics/presentation/pages/predictions_page.dart';
import '../features/financial_obligations/presentation/pages/financial_obligations_page.dart';
import '../features/financial_obligations/presentation/pages/subscriptions_page.dart';
import '../features/financial_obligations/presentation/pages/debts_page.dart';
import '../features/financial_obligations/presentation/pages/loans_page.dart';
import '../features/financial_obligations/presentation/pages/reminders_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/pages/splash_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuthPage = state.uri.toString().startsWith('/auth');
      
      if (authState.status == AuthStatus.initial) {
        return '/splash';
      }
      
      final bool isLoggedIn = authState.status == AuthStatus.authenticated;
      
      if (!isLoggedIn && !isAuthPage) {
        return '/auth/login';
      }
      
      if (isLoggedIn && isAuthPage) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      // ─── Auth Routes ──────────────────────────
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // ─── Main Shell with Bottom Nav ───────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/ai-chat',
            name: 'ai-chat',
            builder: (context, state) => const ChatPage(),
          ),
          GoRoute(
            path: '/financial-planning',
            name: 'financial-planning',
            builder: (context, state) => const FinancialPlanningPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/categories',
            name: 'manage-categories',
            builder: (context, state) => const CategoriesPage(),
          ),
        ],
      ),

      // ─── Full Screen Routes  ──────────────────
      GoRoute(
        path: '/transactions/add',
        name: 'add-transaction',
        builder: (context, state) => const AddTransactionPage(),
      ),
      GoRoute(
        path: '/goals',
        name: 'goals',
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: '/goals/:id',
        name: 'goal-detail',
        builder: (context, state) => GoalDetailPage(goalId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/budgets',
        name: 'budgets',
        builder: (context, state) => const BudgetsPage(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/analytics/predictions',
        name: 'predictions',
        builder: (context, state) => const PredictionsPage(),
      ),
      GoRoute(
        path: '/settings/account',
        name: 'account-details',
        builder: (context, state) => const AccountDetailsPage(),
      ),
      GoRoute(
        path: '/obligations',
        name: 'obligations',
        builder: (context, state) => const FinancialObligationsPage(),
      ),
      GoRoute(
        path: '/obligations/subscriptions',
        name: 'subscriptions',
        builder: (context, state) => const SubscriptionsPage(),
      ),
      GoRoute(
        path: '/obligations/debts',
        name: 'debts',
        builder: (context, state) => const DebtsPage(),
      ),
      GoRoute(
        path: '/obligations/loans',
        name: 'loans',
        builder: (context, state) => const LoansPage(),
      ),
      GoRoute(
        path: '/obligations/reminders',
        name: 'reminders',
        builder: (context, state) => const RemindersPage(),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/financial-planning')) return 1;
    if (location.startsWith('/ai-chat')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/financial-planning');
      case 2:
        context.go('/ai-chat');
      case 3:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndex(context);
    final location = GoRouterState.of(context).uri.toString();
    
    // Hide FAB in AI Chat, Settings, Goals, and Analytics
    final showFab = !location.startsWith('/ai-chat') && 
                    !location.startsWith('/settings') &&
                    !location.startsWith('/goals') &&
                    !location.startsWith('/analytics');

    return Scaffold(
      body: child,
      floatingActionButton: showFab 
        ? FloatingActionButton(
            heroTag: 'quick_add',
            onPressed: () => context.push('/transactions/add'),
            child: const Icon(Icons.add, size: 28),
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: showFab ? const CircularNotchedRectangle() : null,
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => _onTap(context, 0),
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Planning',
              isSelected: currentIndex == 1,
              onTap: () => _onTap(context, 1),
            ),
            if (showFab) const SizedBox(width: 48), // Space for FAB
            _NavItem(
              icon: Icons.smart_toy_rounded,
              label: 'AI Chat',
              isSelected: currentIndex == 2,
              onTap: () => _onTap(context, 2),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              isSelected: currentIndex == 3,
              onTap: () => _onTap(context, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}
