import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_constants.dart';

void main() {
  group('ListView cacheExtent constants', () {
    test('AppConstants.listCacheExtentがdouble型', () {
      expect(AppConstants.listCacheExtent, isA<double>());
    });

    test('定数値が妥当な範囲（100-1000）', () {
      expect(AppConstants.listCacheExtent, greaterThanOrEqualTo(100));
      expect(AppConstants.listCacheExtent, lessThanOrEqualTo(1000));
    });

    test('listCacheExtentがconst', () {
      // constであることはコンパイル時に保証されるが、値の安定性を確認
      const value = AppConstants.listCacheExtent;
      expect(value, 500.0);
    });

    test('AppConstantsクラスが存在', () {
      // AppConstantsの他の定数も存在確認
      expect(AppConstants.defaultListLimit, isA<int>());
      expect(AppConstants.listCacheExtent, isA<double>());
    });
  });
}
