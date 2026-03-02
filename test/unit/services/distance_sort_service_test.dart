import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/distance_sort_service.dart';

void main() {
  group('DistanceSortService', () {
    late DistanceSortService service;

    setUp(() {
      service = DistanceSortService();
    });

    group('calculateDistances', () {
      test('lat/lngあり → 距離付与', () {
        final jobs = [
          {
            'data': {'latitude': 35.6812, 'longitude': 139.7671, 'title': '東京駅'},
            'docId': 'job-001',
          },
        ];

        // 新宿駅付近から計算
        final results = service.calculateDistances(jobs, 35.6896, 139.7006);

        expect(results.length, 1);
        expect(results[0].distanceMeters, isNotNull);
        expect(results[0].distanceMeters!, greaterThan(0));
        expect(results[0].distanceLabel, isNotNull);
        expect(results[0].docId, 'job-001');
      });

      test('lat/lngなし → distanceMeters=null', () {
        final jobs = [
          {
            'data': {'title': '場所不明の案件'},
            'docId': 'job-002',
          },
          {
            'data': {'latitude': null, 'longitude': null, 'title': 'nullの案件'},
            'docId': 'job-003',
          },
        ];

        final results = service.calculateDistances(jobs, 35.6896, 139.7006);

        expect(results.length, 2);
        expect(results[0].distanceMeters, isNull);
        expect(results[0].distanceLabel, isNull);
        expect(results[1].distanceMeters, isNull);
        expect(results[1].distanceLabel, isNull);
      });
    });

    group('sortByDistance', () {
      test('距離昇順、null末尾', () {
        final jobs = [
          const JobWithDistance(
            data: {'title': '遠い'},
            docId: 'job-far',
            distanceMeters: 50000,
            distanceLabel: '50.0km',
          ),
          const JobWithDistance(
            data: {'title': '不明'},
            docId: 'job-unknown',
          ),
          const JobWithDistance(
            data: {'title': '近い'},
            docId: 'job-near',
            distanceMeters: 1200,
            distanceLabel: '1.2km',
          ),
        ];

        final sorted = service.sortByDistance(jobs);

        expect(sorted[0].docId, 'job-near');
        expect(sorted[1].docId, 'job-far');
        expect(sorted[2].docId, 'job-unknown');
      });
    });
  });
}
