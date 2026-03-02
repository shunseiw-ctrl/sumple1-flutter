import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final TextStyle _base = GoogleFonts.notoSansJp();

  // Display
  static TextStyle displayLarge = _base.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMedium = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  // Heading
  static TextStyle headingLarge = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle headingMedium = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle headingSmall = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // Body
  static TextStyle bodyLarge = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // Label
  static TextStyle labelLarge = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle labelMedium = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static TextStyle labelSmall = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppColors.textHint,
  );

  // Special
  static TextStyle salary = _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.salaryHighlight,
  );

  static TextStyle salaryLarge = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.salaryHighlight,
  );

  static TextStyle button = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle buttonSmall = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle chipText = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle badgeText = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static TextStyle appBarTitle = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle sectionTitle = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textHint,
  );

  static TextStyle overline = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );
}
