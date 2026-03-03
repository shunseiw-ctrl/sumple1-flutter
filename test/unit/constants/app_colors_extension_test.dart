import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';

void main() {
  group('AppColorsExtension', () {
    test('ライトテーマ値が正しい', () {
      const ext = AppColorsExtension.light;
      expect(ext.primary, AppColors.ruri);
      expect(ext.background, AppColors.background);
      expect(ext.surface, AppColors.surface);
      expect(ext.textPrimary, AppColors.textPrimary);
      expect(ext.textSecondary, AppColors.textSecondary);
      expect(ext.divider, AppColors.divider);
    });

    test('ダークテーマ値が正しい', () {
      const ext = AppColorsExtension.dark;
      expect(ext.primary, AppColors.ruri);
      expect(ext.background, AppDarkColors.background);
      expect(ext.surface, AppDarkColors.surface);
      expect(ext.textPrimary, AppDarkColors.textPrimary);
      expect(ext.textSecondary, AppDarkColors.textSecondary);
      expect(ext.divider, AppDarkColors.divider);
    });

    test('copyWithが動作する', () {
      const ext = AppColorsExtension.light;
      final copied = ext.copyWith(background: Colors.red);
      expect(copied.background, Colors.red);
      expect(copied.primary, ext.primary);
      expect(copied.surface, ext.surface);
    });

    test('lerpが中間値を返す', () {
      const light = AppColorsExtension.light;
      const dark = AppColorsExtension.dark;
      final mid = light.lerp(dark, 0.5);
      expect(mid.background, isNotNull);
      expect(mid.background, isNot(equals(light.background)));
      expect(mid.background, isNot(equals(dark.background)));
    });

    test('BuildContext extensionがライトテーマで動作', () {
      // ThemeExtensionの登録テスト
      final theme = ThemeData(
        extensions: const [AppColorsExtension.light],
      );
      final ext = theme.extension<AppColorsExtension>();
      expect(ext, isNotNull);
      expect(ext!.background, AppColors.background);
    });

    test('BuildContext extensionがダークテーマで動作', () {
      final theme = ThemeData(
        brightness: Brightness.dark,
        extensions: const [AppColorsExtension.dark],
      );
      final ext = theme.extension<AppColorsExtension>();
      expect(ext, isNotNull);
      expect(ext!.background, AppDarkColors.background);
    });

    test('全カラー定数がExtensionにマッピングされている', () {
      const ext = AppColorsExtension.light;
      // 全フィールドが非null
      expect(ext.primary, isNotNull);
      expect(ext.primaryLight, isNotNull);
      expect(ext.primaryDark, isNotNull);
      expect(ext.primaryPale, isNotNull);
      expect(ext.primarySurface, isNotNull);
      expect(ext.background, isNotNull);
      expect(ext.surface, isNotNull);
      expect(ext.surfaceElevated, isNotNull);
      expect(ext.textPrimary, isNotNull);
      expect(ext.textSecondary, isNotNull);
      expect(ext.textHint, isNotNull);
      expect(ext.textOnPrimary, isNotNull);
      expect(ext.divider, isNotNull);
      expect(ext.border, isNotNull);
      expect(ext.borderLight, isNotNull);
      expect(ext.success, isNotNull);
      expect(ext.successLight, isNotNull);
      expect(ext.warning, isNotNull);
      expect(ext.warningLight, isNotNull);
      expect(ext.error, isNotNull);
      expect(ext.errorLight, isNotNull);
      expect(ext.info, isNotNull);
      expect(ext.infoLight, isNotNull);
      expect(ext.chipSelected, isNotNull);
      expect(ext.chipUnselected, isNotNull);
      expect(ext.chipTextSelected, isNotNull);
      expect(ext.chipTextUnselected, isNotNull);
      expect(ext.cardShadow, isNotNull);
      expect(ext.elevatedShadow, isNotNull);
      expect(ext.salaryHighlight, isNotNull);
      expect(ext.salaryBg, isNotNull);
      expect(ext.cardGradient, isNotNull);
      expect(ext.primaryGradient, isNotNull);
      expect(ext.heroGradient, isNotNull);
    });

    test('light/darkで異なる値を持つ色がある', () {
      const light = AppColorsExtension.light;
      const dark = AppColorsExtension.dark;
      expect(light.background, isNot(equals(dark.background)));
      expect(light.surface, isNot(equals(dark.surface)));
      expect(light.textPrimary, isNot(equals(dark.textPrimary)));
      expect(light.divider, isNot(equals(dark.divider)));
    });
  });
}
