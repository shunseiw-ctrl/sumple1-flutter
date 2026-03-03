import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/config/feature_flags.dart';

void main() {
  group('Phase 21 Integration', () {
    test('ThemeExtension light/darkが登録可能', () {
      final lightTheme = ThemeData(
        extensions: const [AppColorsExtension.light],
      );
      final darkTheme = ThemeData(
        brightness: Brightness.dark,
        extensions: const [AppColorsExtension.dark],
      );

      expect(lightTheme.extension<AppColorsExtension>(), isNotNull);
      expect(darkTheme.extension<AppColorsExtension>(), isNotNull);
      expect(
        lightTheme.extension<AppColorsExtension>()!.background,
        isNot(equals(darkTheme.extension<AppColorsExtension>()!.background)),
      );
    });

    test('フィーチャーフラグがStripeを無効化', () {
      expect(FeatureFlags.enableStripePayments, isFalse);
      expect(FeatureFlags.enableEarlyPayment, isFalse);
    });

    test('app_en.arbが存在する', () {
      expect(File('lib/l10n/app_en.arb').existsSync(), isTrue);
    });

    test('app_ja.arbが存在する', () {
      expect(File('lib/l10n/app_ja.arb').existsSync(), isTrue);
    });

    test('locale_provider.dartが存在する', () {
      expect(File('lib/core/providers/locale_provider.dart').existsSync(), isTrue);
    });

    test('build_context_extensions.dartが存在する', () {
      expect(File('lib/core/extensions/build_context_extensions.dart').existsSync(), isTrue);
    });
  });
}
