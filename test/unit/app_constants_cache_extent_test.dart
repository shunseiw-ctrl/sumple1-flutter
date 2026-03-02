import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_constants.dart';

void main() {
  group('AppConstants cacheExtent', () {
    test('listCacheExtent == 500.0', () {
      expect(AppConstants.listCacheExtent, 500.0);
    });

    test('listCacheExtent > 0', () {
      expect(AppConstants.listCacheExtent, greaterThan(0));
    });
  });
}
