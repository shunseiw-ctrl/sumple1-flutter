import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Store Readiness', () {
    test('Info.plistに必要な全権限キーが存在する', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist.contains('NSCameraUsageDescription'), isTrue);
      expect(plist.contains('NSPhotoLibraryUsageDescription'), isTrue);
      expect(plist.contains('NSLocationWhenInUseUsageDescription'), isTrue);
      expect(plist.contains('ITSAppUsesNonExemptEncryption'), isTrue);
    });

    test('プライバシーポリシーHTMLが存在し空でない', () {
      final file = File('landing/privacy-policy.html');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(100));
      expect(content.contains('ALBAWORK'), isTrue);
    });

    test('利用規約HTMLが存在し空でない', () {
      final file = File('landing/terms-of-service.html');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(100));
      expect(content.contains('ALBAWORK'), isTrue);
    });

    test('firebase.jsonにHosting設定が存在する', () {
      final content = File('firebase.json').readAsStringSync();
      expect(content.contains('"hosting"'), isTrue);
      expect(content.contains('"public"'), isTrue);
    });
  });
}
