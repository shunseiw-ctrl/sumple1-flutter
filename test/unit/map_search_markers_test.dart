import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('MapSearch マーカー生成ロジック', () {
    // マーカー生成ロジックを分離してテスト（GoogleMap widget自体はプラットフォーム依存）
    Set<Marker> buildMarkers(List<Map<String, dynamic>> jobs) {
      final markers = <Marker>{};
      for (final job in jobs) {
        final data = job['data'] as Map<String, dynamic>? ?? {};
        final docId = job['docId'] as String? ?? '';
        final lat = _parseDouble(data['latitude']);
        final lng = _parseDouble(data['longitude']);

        if (lat == null || lng == null) continue;

        markers.add(Marker(
          markerId: MarkerId(docId),
          position: LatLng(lat, lng),
        ));
      }
      return markers;
    }

    test('lat/lngあるjob→マーカー生成', () {
      final jobs = [
        {
          'data': {'latitude': 35.6812, 'longitude': 139.7671, 'title': '東京駅'},
          'docId': 'job-001',
        },
        {
          'data': {'latitude': 35.4657, 'longitude': 139.6223, 'title': '横浜駅'},
          'docId': 'job-002',
        },
      ];

      final markers = buildMarkers(jobs);

      expect(markers.length, 2);
      expect(markers.any((m) => m.markerId.value == 'job-001'), isTrue);
      expect(markers.any((m) => m.markerId.value == 'job-002'), isTrue);
    });

    test('lat/lngなしjob→マーカースキップ', () {
      final jobs = [
        {
          'data': {'latitude': 35.6812, 'longitude': 139.7671, 'title': '東京駅'},
          'docId': 'job-001',
        },
        {
          'data': {'title': '場所不明'},
          'docId': 'job-002',
        },
        {
          'data': {'latitude': null, 'longitude': null, 'title': 'nullの案件'},
          'docId': 'job-003',
        },
      ];

      final markers = buildMarkers(jobs);

      expect(markers.length, 1);
      expect(markers.first.markerId.value, 'job-001');
    });
  });
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
