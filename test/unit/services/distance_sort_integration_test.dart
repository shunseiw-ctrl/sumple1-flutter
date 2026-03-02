import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/distance_sort_service.dart';
import 'package:sumple1/core/services/location_service.dart';

void main() {
  group('DistanceSortService 統合テスト', () {
    late DistanceSortService service;

    setUp(() {
      service = DistanceSortService();
    });

    test('sortByDistance: 昇順確認', () {
      final jobs = [
        const JobWithDistance(data: {}, docId: 'far', distanceMeters: 50000),
        const JobWithDistance(data: {}, docId: 'mid', distanceMeters: 10000),
        const JobWithDistance(data: {}, docId: 'near', distanceMeters: 1000),
      ];

      final sorted = service.sortByDistance(jobs);

      expect(sorted[0].docId, 'near');
      expect(sorted[1].docId, 'mid');
      expect(sorted[2].docId, 'far');
    });

    test('sortByDistance: null距離は末尾', () {
      final jobs = [
        const JobWithDistance(data: {}, docId: 'unknown1'),
        const JobWithDistance(data: {}, docId: 'near', distanceMeters: 500),
        const JobWithDistance(data: {}, docId: 'unknown2'),
      ];

      final sorted = service.sortByDistance(jobs);

      expect(sorted[0].docId, 'near');
      expect(sorted[1].docId, 'unknown1');
      expect(sorted[2].docId, 'unknown2');
    });

    test('キャッシュ: calculateDistancesの精度（東京→横浜 ≈ 28km）', () {
      // 東京駅: 35.6812, 139.7671
      // 横浜駅: 35.4657, 139.6223
      final distance = LocationService.calculateDistance(
        35.6812, 139.7671,
        35.4657, 139.6223,
      );

      // 約27-29km
      expect(distance / 1000, closeTo(28, 2));
    });

    test('calculateDistances: 複数案件の距離付与', () {
      final jobs = [
        {
          'data': {'latitude': 35.6812, 'longitude': 139.7671, 'title': '東京駅'},
          'docId': 'tokyo',
        },
        {
          'data': {'latitude': 35.4657, 'longitude': 139.6223, 'title': '横浜駅'},
          'docId': 'yokohama',
        },
        {
          'data': {'title': '場所不明'},
          'docId': 'unknown',
        },
      ];

      // 新宿駅付近から
      final results = service.calculateDistances(jobs, 35.6896, 139.7006);
      final sorted = service.sortByDistance(results);

      // 東京駅が最も近い（新宿からの距離）
      expect(sorted[0].docId, isNot('unknown'));
      expect(sorted.last.docId, 'unknown');
      expect(sorted.last.distanceMeters, isNull);
    });
  });
}
