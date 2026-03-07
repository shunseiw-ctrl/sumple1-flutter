import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_version.dart';

void main() {
  group('AppVersion', () {
    test('appVersion_定数が定義されている_1.0.0を返す', () {
      expect(AppVersion.appVersion, '1.0.0');
    });

    test('appVersion_セマンティックバージョニング形式_正しいフォーマット', () {
      final regex = RegExp(r'^\d+\.\d+\.\d+$');
      expect(regex.hasMatch(AppVersion.appVersion), isTrue);
    });
  });
}
