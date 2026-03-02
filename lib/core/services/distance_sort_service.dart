import '../services/location_service.dart';
import '../utils/distance_utils.dart';

/// 距離計算・キャッシュ・ソートサービス
class DistanceSortService {
  /// ユーザー位置キャッシュ（5分間有効）
  double? _cachedLat;
  double? _cachedLng;
  DateTime? _cachedAt;
  static const _cacheExpiry = Duration(minutes: 5);

  /// 現在位置を取得（キャッシュ活用）
  Future<({double lat, double lng})> getCurrentPosition() async {
    final now = DateTime.now();
    if (_cachedLat != null &&
        _cachedLng != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheExpiry) {
      return (lat: _cachedLat!, lng: _cachedLng!);
    }

    final position = await LocationService.getCurrentPosition();
    _cachedLat = position.latitude;
    _cachedLng = position.longitude;
    _cachedAt = now;
    return (lat: position.latitude, lng: position.longitude);
  }

  /// キャッシュをクリア（テスト用）
  void clearCache() {
    _cachedLat = null;
    _cachedLng = null;
    _cachedAt = null;
  }

  /// 案件に距離情報を付与
  List<JobWithDistance> calculateDistances(
    List<Map<String, dynamic>> jobDocs,
    double userLat,
    double userLng,
  ) {
    return jobDocs.map((job) {
      final data = job['data'] as Map<String, dynamic>? ?? {};
      final docId = job['docId'] as String? ?? '';

      final lat = _parseDouble(data['latitude']);
      final lng = _parseDouble(data['longitude']);

      double? distanceMeters;
      String? distanceLabel;

      if (lat != null && lng != null) {
        distanceMeters = LocationService.calculateDistance(
          userLat,
          userLng,
          lat,
          lng,
        );
        distanceLabel = DistanceUtils.formatDistance(distanceMeters);
      }

      return JobWithDistance(
        data: data,
        docId: docId,
        distanceMeters: distanceMeters,
        distanceLabel: distanceLabel,
      );
    }).toList();
  }

  /// 距離昇順ソート（lat/lngなしは末尾）
  List<JobWithDistance> sortByDistance(List<JobWithDistance> jobs) {
    final sorted = List<JobWithDistance>.from(jobs);
    sorted.sort((a, b) {
      if (a.distanceMeters == null && b.distanceMeters == null) return 0;
      if (a.distanceMeters == null) return 1;
      if (b.distanceMeters == null) return -1;
      return a.distanceMeters!.compareTo(b.distanceMeters!);
    });
    return sorted;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// 距離情報付き案件
class JobWithDistance {
  final Map<String, dynamic> data;
  final String docId;
  final double? distanceMeters;
  final String? distanceLabel;

  const JobWithDistance({
    required this.data,
    required this.docId,
    this.distanceMeters,
    this.distanceLabel,
  });
}
