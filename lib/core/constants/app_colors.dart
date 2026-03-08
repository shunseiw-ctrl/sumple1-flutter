import 'package:flutter/material.dart';

/// テーマ対応のカラー拡張
/// `context.appColors.xxx` でアクセスする
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryPale,
    required this.primarySurface,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textOnPrimary,
    required this.divider,
    required this.border,
    required this.borderLight,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.chipSelected,
    required this.chipUnselected,
    required this.chipTextSelected,
    required this.chipTextUnselected,
    required this.cardShadow,
    required this.elevatedShadow,
    required this.salaryHighlight,
    required this.salaryBg,
    required this.cardGradient,
    required this.primaryGradient,
    required this.heroGradient,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryPale;
  final Color primarySurface;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textOnPrimary;
  final Color divider;
  final Color border;
  final Color borderLight;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;
  final Color chipSelected;
  final Color chipUnselected;
  final Color chipTextSelected;
  final Color chipTextUnselected;
  final Color cardShadow;
  final Color elevatedShadow;
  final Color salaryHighlight;
  final Color salaryBg;
  final LinearGradient cardGradient;
  final LinearGradient primaryGradient;
  final LinearGradient heroGradient;
  final Color skeletonBase;
  final Color skeletonHighlight;

  static const light = AppColorsExtension(
    primary: AppColors.ruri,
    primaryLight: AppColors.ruriLight,
    primaryDark: AppColors.ruriDark,
    primaryPale: AppColors.ruriPale,
    primarySurface: AppColors.ruriSurface,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    textOnPrimary: AppColors.textOnPrimary,
    divider: AppColors.divider,
    border: AppColors.border,
    borderLight: AppColors.borderLight,
    success: AppColors.success,
    successLight: AppColors.successLight,
    warning: AppColors.warning,
    warningLight: AppColors.warningLight,
    error: AppColors.error,
    errorLight: AppColors.errorLight,
    info: AppColors.info,
    infoLight: AppColors.infoLight,
    chipSelected: AppColors.chipSelected,
    chipUnselected: AppColors.chipUnselected,
    chipTextSelected: AppColors.chipTextSelected,
    chipTextUnselected: AppColors.chipTextUnselected,
    cardShadow: AppColors.cardShadow,
    elevatedShadow: AppColors.elevatedShadow,
    salaryHighlight: AppColors.salaryHighlight,
    salaryBg: AppColors.salaryBg,
    cardGradient: AppColors.cardGradient,
    primaryGradient: AppColors.primaryGradient,
    heroGradient: AppColors.heroGradient,
    skeletonBase: AppColors.skeletonBase,
    skeletonHighlight: AppColors.skeletonHighlight,
  );

  static const dark = AppColorsExtension(
    primary: AppColors.ruri,
    primaryLight: AppColors.ruriLight,
    primaryDark: AppColors.ruriDark,
    primaryPale: AppDarkColors.ruriPale,
    primarySurface: AppDarkColors.ruriSurface,
    background: AppDarkColors.background,
    surface: AppDarkColors.surface,
    surfaceElevated: AppDarkColors.surfaceElevated,
    textPrimary: AppDarkColors.textPrimary,
    textSecondary: AppDarkColors.textSecondary,
    textHint: AppDarkColors.textHint,
    textOnPrimary: AppDarkColors.textOnPrimary,
    divider: AppDarkColors.divider,
    border: AppDarkColors.border,
    borderLight: AppDarkColors.borderLight,
    success: AppColors.success,
    successLight: AppColors.successLight,
    warning: AppColors.warning,
    warningLight: AppColors.warningLight,
    error: AppColors.error,
    errorLight: AppColors.errorLight,
    info: AppColors.info,
    infoLight: AppColors.infoLight,
    chipSelected: AppColors.ruri,
    chipUnselected: AppDarkColors.chipUnselected,
    chipTextSelected: Colors.white,
    chipTextUnselected: AppDarkColors.chipTextUnselected,
    cardShadow: AppDarkColors.cardShadow,
    elevatedShadow: AppDarkColors.elevatedShadow,
    salaryHighlight: AppColors.salaryHighlight,
    salaryBg: AppDarkColors.salaryBg,
    cardGradient: AppDarkColors.cardGradient,
    primaryGradient: AppColors.primaryGradient,
    heroGradient: AppColors.heroGradient,
    skeletonBase: AppDarkColors.skeletonBase,
    skeletonHighlight: AppDarkColors.skeletonHighlight,
  );

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? primaryPale,
    Color? primarySurface,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? textOnPrimary,
    Color? divider,
    Color? border,
    Color? borderLight,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? error,
    Color? errorLight,
    Color? info,
    Color? infoLight,
    Color? chipSelected,
    Color? chipUnselected,
    Color? chipTextSelected,
    Color? chipTextUnselected,
    Color? cardShadow,
    Color? elevatedShadow,
    Color? salaryHighlight,
    Color? salaryBg,
    LinearGradient? cardGradient,
    LinearGradient? primaryGradient,
    LinearGradient? heroGradient,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryPale: primaryPale ?? this.primaryPale,
      primarySurface: primarySurface ?? this.primarySurface,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      chipSelected: chipSelected ?? this.chipSelected,
      chipUnselected: chipUnselected ?? this.chipUnselected,
      chipTextSelected: chipTextSelected ?? this.chipTextSelected,
      chipTextUnselected: chipTextUnselected ?? this.chipTextUnselected,
      cardShadow: cardShadow ?? this.cardShadow,
      elevatedShadow: elevatedShadow ?? this.elevatedShadow,
      salaryHighlight: salaryHighlight ?? this.salaryHighlight,
      salaryBg: salaryBg ?? this.salaryBg,
      cardGradient: cardGradient ?? this.cardGradient,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      heroGradient: heroGradient ?? this.heroGradient,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryPale: Color.lerp(primaryPale, other.primaryPale, t)!,
      primarySurface: Color.lerp(primarySurface, other.primarySurface, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      chipSelected: Color.lerp(chipSelected, other.chipSelected, t)!,
      chipUnselected: Color.lerp(chipUnselected, other.chipUnselected, t)!,
      chipTextSelected: Color.lerp(chipTextSelected, other.chipTextSelected, t)!,
      chipTextUnselected: Color.lerp(chipTextUnselected, other.chipTextUnselected, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      elevatedShadow: Color.lerp(elevatedShadow, other.elevatedShadow, t)!,
      salaryHighlight: Color.lerp(salaryHighlight, other.salaryHighlight, t)!,
      salaryBg: Color.lerp(salaryBg, other.salaryBg, t)!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
    );
  }
}

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
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFEEF2FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
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

  // Skeleton
  static const Color skeletonBase = Color(0xFFEEEFF1);
  static const Color skeletonHighlight = Color(0xFFF8F8FA);
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

  // Skeleton
  static const Color skeletonBase = Color(0xFF2A2A2A);
  static const Color skeletonHighlight = Color(0xFF363636);

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
