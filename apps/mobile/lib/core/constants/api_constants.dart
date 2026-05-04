import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    
    if (kIsWeb) return 'https://backend-finance-production-2637.up.railway.app/api/v1/';
    if (Platform.isAndroid) return 'https://backend-finance-production-2637.up.railway.app/api/v1/';
    return 'https://backend-finance-production-2637.up.railway.app/api/v1/';
  }

  static const String googleClientId = '452414717624-bkfptr7c87e6s7aq8rr46qpll6uqu67i.apps.googleusercontent.com';

  // Auth
  static String get authSignUp => '${baseUrl}auth/sign-up/email';
  static String get authSignIn => '${baseUrl}auth/sign-in/email';
  static String get authSignOut => '${baseUrl}auth/sign-out';
  static String get authSession => '${baseUrl}auth/get-session';
  static String get authGoogle => '${baseUrl}auth/google';

  // Users
  static String get userMe => '${baseUrl}users/me';
  static String get userSummary => '${baseUrl}users/me/summary';

  // Transactions
  static String get transactions => '${baseUrl}transactions';
  static String get transactionsMonthlySummary => '${baseUrl}transactions/summary/monthly';
  static String get transactionsByCategory => '${baseUrl}transactions/summary/by-category';

  // Budgets
  static String get budgets => '${baseUrl}budgets';
  static String get budgetStatus => '${baseUrl}budgets/status';

  // Goals
  static String get goals => '${baseUrl}goals';

  // Analytics
  static String get analyticsDashboard => '${baseUrl}analytics/dashboard';
  static String get analyticsMonthlyReport => '${baseUrl}analytics/monthly-report';
  static String get analyticsTrends => '${baseUrl}analytics/trends';
  static String get analyticsTopCategories => '${baseUrl}analytics/top-categories';
  static String get analyticsInsights => '${baseUrl}analytics/insights';

  // AI Chat
  static String get aiChat => '${baseUrl}ai/chat';
  static String get aiSessions => '${baseUrl}ai/sessions';
  static String get aiSimulate => '${baseUrl}ai/simulate';

  // Notifications
  static String get notifications => '${baseUrl}notifications';
  static String get notificationsUnreadCount => '${baseUrl}notifications/unread-count';
  static String get notificationsReadAll => '${baseUrl}notifications/read-all';

  // Categories
  static String get categories => '${baseUrl}categories';
  static String category(String id) => '${baseUrl}categories/$id';
}
