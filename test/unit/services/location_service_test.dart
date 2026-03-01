import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/location_service.dart';

void main() {
  group('LocationService', () {
    group('calculateDistance', () {
      test('同一地点の距離は0m', () {
        final distance = LocationService.calculateDistance(
          35.6895, 139.6917,
          35.6895, 139.6917,
        );
        expect(distance, closeTo(0.0, 0.1));
      });

      test('東京駅-横浜駅 約27km', () {
        // 東京駅: 35.6812, 139.7671
        // 横浜駅: 35.4657, 139.6225
        final distance = LocationService.calculateDistance(
          35.6812, 139.7671,
          35.4657, 139.6225,
        );
        // 約27km（25-30kmの範囲）
        expect(distance, greaterThan(25000));
        expect(distance, lessThan(30000));
      });

      test('100m境界値の検証', () {
        // 緯度の1度 ≈ 111km、0.0009度 ≈ 100m
        final distance = LocationService.calculateDistance(
          35.6895, 139.6917,
          35.6904, 139.6917,
        );
        // 約100m（80-120mの範囲）
        expect(distance, greaterThan(80));
        expect(distance, lessThan(120));
      });

      test('対蹠点の距離は約20000km', () {
        // 地球の半径約6371km → 対蹠点距離 ≈ pi * 6371km ≈ 20015km
        final distance = LocationService.calculateDistance(
          0.0, 0.0,
          0.0, 180.0,
        );
        // 約20000km
        expect(distance, greaterThan(19500000));
        expect(distance, lessThan(20100000));
      });

      test('負の座標（南半球・西半球）でも計算できる', () {
        // シドニー: -33.8688, 151.2093
        // 東京: 35.6895, 139.6917
        final distance = LocationService.calculateDistance(
          -33.8688, 151.2093,
          35.6895, 139.6917,
        );
        // 約7800km
        expect(distance, greaterThan(7500000));
        expect(distance, lessThan(8200000));
      });

      test('非常に近い2点の距離', () {
        // 約10m離れた2点
        final distance = LocationService.calculateDistance(
          35.6895, 139.6917,
          35.68959, 139.6917,
        );
        expect(distance, greaterThan(5));
        expect(distance, lessThan(20));
      });
    });

    group('LocationException', () {
      test('メッセージを保持する', () {
        final e = LocationException('テストエラー');
        expect(e.message, 'テストエラー');
      });

      test('toStringでメッセージを返す', () {
        final e = LocationException('位置情報が無効です');
        expect(e.toString(), '位置情報が無効です');
      });
    });
  });
}
