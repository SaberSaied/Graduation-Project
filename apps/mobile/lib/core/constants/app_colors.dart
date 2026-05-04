import 'package:flutter/material.dart';

class AppColors {
  // ─── Light Mode ───────────────────────────────
  static const Color primaryLight = Color(0xFF4F6EF5);
  static const Color primaryLightVariant = Color(0xFF3B5BDB);
  static const Color accentLight = Color(0xFF00C896);
  static const Color errorLight = Color(0xFFFF5252);
  static const Color warningLight = Color(0xFFFFB020);
  static const Color backgroundLight = Color(0xFFF8F9FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1D2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color shimmerBaseLight = Color(0xFFE0E0E0);
  static const Color shimmerHighlightLight = Color(0xFFF5F5F5);

  // ─── Dark Mode ────────────────────────────────
  static const Color primaryDark = Color(0xFF6B8AFF);
  static const Color primaryDarkVariant = Color(0xFF5477FF);
  static const Color accentDark = Color(0xFF00E6A8);
  static const Color errorDark = Color(0xFFFF6B6B);
  static const Color warningDark = Color(0xFFFFCB57);
  static const Color backgroundDark = Color(0xFF0F1117);
  static const Color surfaceDark = Color(0xFF1C1E2A);
  static const Color cardDark = Color(0xFF242636);
  static const Color textPrimaryDark = Color(0xFFF1F2FF);
  static const Color textSecondaryDark = Color(0xFF9CA3B8);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  static const Color dividerDark = Color(0xFF2D2F3E);
  static const Color shimmerBaseDark = Color(0xFF2D2F3E);
  static const Color shimmerHighlightDark = Color(0xFF3D3F4E);

  // ─── Shared Colors ────────────────────────────
  static const Color income = Color(0xFF00C896);
  static const Color expense = Color(0xFFFF5252);
  static const Color savings = Color(0xFF4F6EF5);

  // ─── Gradient ─────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F6EF5), Color(0xFF7B93FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00E6A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
