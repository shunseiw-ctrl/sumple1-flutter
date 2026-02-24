import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand - 瑠璃色
  static const Color ruri = Color(0xFF1E50A2);
  static const Color ruriLight = Color(0xFF3A6FBF);
  static const Color ruriDark = Color(0xFF163D7A);
  static const Color ruriPale = Color(0xFFE8EEF7);
  static const Color ruriSurface = Color(0xFFF0F4FA);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E50A2), Color(0xFF3A7BD5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F2B5B), Color(0xFF1E50A2), Color(0xFF3A7BD5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neutral / Background
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFCFCFD);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFEEF0F2);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color lineGreen = Color(0xFF06C755);

  // Chips
  static const Color chipSelected = ruri;
  static const Color chipUnselected = Color(0xFFF3F4F6);
  static const Color chipTextSelected = Colors.white;
  static const Color chipTextUnselected = Color(0xFF374151);

  // Shadows
  static const Color cardShadow = Color(0x0D000000);
  static const Color elevatedShadow = Color(0x1A000000);

  // Card specific
  static const Color salaryHighlight = Color(0xFF1E50A2);
  static const Color salaryBg = Color(0xFFF0F4FA);
}

class AppDarkColors {
  AppDarkColors._();

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textHint = Color(0xFF707070);
  static const Color textOnPrimary = Colors.white;
  static const Color divider = Color(0xFF333333);
  static const Color border = Color(0xFF404040);
  static const Color borderLight = Color(0xFF2A2A2A);

  static const Color ruriPale = Color(0xFF1A2D4A);
  static const Color ruriSurface = Color(0xFF152238);

  static const Color cardShadow = Color(0x00000000);
  static const Color elevatedShadow = Color(0x00000000);

  static const Color chipUnselected = Color(0xFF2A2A2A);
  static const Color chipTextUnselected = Color(0xFFD0D0D0);

  static const Color salaryBg = Color(0xFF1A2D4A);

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
