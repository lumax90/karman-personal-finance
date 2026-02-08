import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Zinc-based neutral palette (shadcn-inspired)
  static const Color zinc50 = Color(0xFFFAFAFA);
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
  static const Color zinc950 = Color(0xFF09090B);

  // Primary accent
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryLight = Color(0xFF3B82F6); // Blue-500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue-700
  static const Color primaryMuted = Color(0xFFDBEAFE); // Blue-100

  // Semantic colors
  static const Color success = Color(0xFF16A34A);
  static const Color successMuted = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningMuted = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorMuted = Color(0xFFFEE2E2);

  // Income/Expense
  static const Color income = Color(0xFF16A34A);
  static const Color incomeMuted = Color(0xFFDCFCE7);
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseMuted = Color(0xFFFEE2E2);

  // Account mode colors
  static const Color personal = Color(0xFF8B5CF6); // Violet
  static const Color personalMuted = Color(0xFFEDE9FE);
  static const Color business = Color(0xFF0EA5E9); // Sky
  static const Color businessMuted = Color(0xFFE0F2FE);

  // Background & Surface
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF4F4F5);
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderLight = Color(0xFFF4F4F5);

  // Text
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textTertiary = Color(0xFFA1A1AA);
  static const Color textInverse = Colors.white;
}
