import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_constants.dart';

void main() {
  group('FirestoreSetup constants', () {
    test('AppConstants.firestoreCacheSizeBytes == 100MB', () {
      expect(AppConstants.firestoreCacheSizeBytes, 100 * 1024 * 1024);
    });

    test('firestoreCacheSizeBytesが正の整数', () {
      expect(AppConstants.firestoreCacheSizeBytes, greaterThan(0));
      expect(AppConstants.firestoreCacheSizeBytes, isA<int>());
    });

    test('firestoreCacheSizeBytes は妥当な範囲', () {
      // 10MB以上、500MB以下
      expect(AppConstants.firestoreCacheSizeBytes, greaterThanOrEqualTo(10 * 1024 * 1024));
      expect(AppConstants.firestoreCacheSizeBytes, lessThanOrEqualTo(500 * 1024 * 1024));
    });
  });
}
