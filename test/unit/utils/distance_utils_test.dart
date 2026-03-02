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
      test('範囲内はtrue・範囲外はfalse', () {
        expect(DistanceUtils.isWithinRange(30000), isTrue);
        expect(DistanceUtils.isWithinRange(50000), isTrue);
        expect(DistanceUtils.isWithinRange(50001), isFalse);
        expect(DistanceUtils.isWithinRange(100000), isFalse);
      });
    });
  });
}
