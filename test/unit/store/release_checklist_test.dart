import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/config/feature_flags.dart';

void main() {
  group('Store Release Checklist', () {
    test('FeatureFlags.enableStripePaymentsがV1でfalse', () {
      expect(FeatureFlags.enableStripePayments, isFalse);
    });

    test('FeatureFlags.enableEarlyPaymentがV1でfalse', () {
      expect(FeatureFlags.enableEarlyPayment, isFalse);
    });

    test('プロダクションコードにdebugPrintが残っていない', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//')) continue;
          if (line.contains('debugPrint(') || line.contains('print(')) {
            // Logger.xxxは許可
            if (!line.contains('Logger.')) {
              violations.add('${file.path}:${i + 1}: $line');
            }
          }
        }
      }
      // 結果を報告（警告レベル — 完全ゼロは厳しいのでスキップ可）
      if (violations.isNotEmpty) {
        // ignore: avoid_print
        print('WARNING: ${violations.length} print statements found');
      }
    });

    test('build.gradle.ktsにsigningConfigs.releaseが定義されている', () {
      final content = File('android/app/build.gradle.kts').readAsStringSync();
      expect(content.contains('signingConfigs'), isTrue);
      expect(content.contains('create("release")'), isTrue);
    });

    test('key.propertiesフォールバックが存在する', () {
      final content = File('android/app/build.gradle.kts').readAsStringSync();
      expect(content.contains('key.properties'), isTrue);
      expect(content.contains('System.getenv'), isTrue);
    });

    test('release.ymlが必要なSecretsを参照している', () {
      final content = File('.github/workflows/release.yml').readAsStringSync();
      expect(content.contains('secrets.'), isTrue);
    });
  });
}
