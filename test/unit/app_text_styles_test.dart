import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_colors.dart';

void main() {
  group('AppTextStyles', () {
    testWidgets('displayLarge: fontSize == 40', (tester) async {
      expect(AppTextStyles.displayLarge.fontSize, 40);
    });

    testWidgets('bodyMedium: fontSize == 14', (tester) async {
      expect(AppTextStyles.bodyMedium.fontSize, 14);
    });

    testWidgets('labelSmall: fontSize == 11', (tester) async {
      expect(AppTextStyles.labelSmall.fontSize, 11);
    });

    testWidgets('salary: color == AppColors.salaryHighlight', (tester) async {
      expect(AppTextStyles.salary.color, AppColors.salaryHighlight);
    });

    testWidgets('button: fontWeight == FontWeight.w700', (tester) async {
      expect(AppTextStyles.button.fontWeight, FontWeight.w700);
    });

    testWidgets('全スタイルが同一fontFamilyを共有', (tester) async {
      final family = AppTextStyles.displayLarge.fontFamily;
      expect(family, isNotNull);
      expect(AppTextStyles.bodyMedium.fontFamily, family);
      expect(AppTextStyles.labelSmall.fontFamily, family);
      expect(AppTextStyles.salary.fontFamily, family);
      expect(AppTextStyles.button.fontFamily, family);
      expect(AppTextStyles.appBarTitle.fontFamily, family);
    });

    testWidgets('appBarTitle: fontSize == 18', (tester) async {
      expect(AppTextStyles.appBarTitle.fontSize, 18);
    });
  });
}
