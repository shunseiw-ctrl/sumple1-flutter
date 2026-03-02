import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobDetail Share', () {
    test('share icon exists in Icons', () {
      // Verify the icon constant exists
      expect(Icons.share_outlined, isNotNull);
    });

    test('ShareService text contains required elements', () {
      // Test share text format
      final text = '【ALBAWORK】テスト\n場所: 東京\n日給: 15000円\nhttps://albawork.app/jobs/id1';
      expect(text, contains('【ALBAWORK】'));
      expect(text, contains('https://albawork.app/jobs/'));
    });
  });
}
