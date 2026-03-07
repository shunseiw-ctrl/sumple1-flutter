import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/distance_utils.dart';

void main() {
  group('DistanceUtils', () {
    group('formatDistance', () {
      test('1000m未満はメートル表示', () {
        expect(DistanceUtils.formatDistance(850), '850m');
        expect(DistanceUtils.formatDistance(0), '0m');
        expect(DistanceUtils.formatDistance(999.9), '1000m');
        expect(DistanceUtils.formatDistance(100), '100m');
      });

      test('1000m以上100km未満は小数1桁のkm表示', () {
        expect(DistanceUtils.formatDistance(1200), '1.2km');
        expect(DistanceUtils.formatDistance(1000), '1.0km');
        expect(DistanceUtils.formatDistance(50000), '50.0km');
        expect(DistanceUtils.formatDistance(99999), '100.0km');
      });

      test('100km以上は整数km表示', () {
        expect(DistanceUtils.formatDistance(105000), '105km');
        expect(DistanceUtils.formatDistance(100000), '100km');
        expect(DistanceUtils.formatDistance(500000), '500km');
      });
    });

    group('isWithinRange', () {
      test('デフォルト50km_範囲内はtrue', () {
        expect(DistanceUtils.isWithinRange(0), isTrue);
        expect(DistanceUtils.isWithinRange(30000), isTrue);
        expect(DistanceUtils.isWithinRange(50000), isTrue);
      });

      test('デフォルト50km_範囲外はfalse', () {
        expect(DistanceUtils.isWithinRange(50001), isFalse);
        expect(DistanceUtils.isWithinRange(100000), isFalse);
      });

      test('カスタムmaxMeters_指定範囲で判定される', () {
        expect(DistanceUtils.isWithinRange(5000, maxMeters: 10000), isTrue);
        expect(DistanceUtils.isWithinRange(10000, maxMeters: 10000), isTrue);
        expect(DistanceUtils.isWithinRange(10001, maxMeters: 10000), isFalse);
      });

      test('カスタムmaxMeters_大きな範囲指定', () {
        expect(DistanceUtils.isWithinRange(200000, maxMeters: 500000), isTrue);
        expect(DistanceUtils.isWithinRange(500001, maxMeters: 500000), isFalse);
      });
    });
  });
}
