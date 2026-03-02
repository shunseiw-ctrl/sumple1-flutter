/// 距離のフォーマット・範囲チェックユーティリティ
class DistanceUtils {
  DistanceUtils._();

  /// メートル→人間が読める形式: 850m / 1.2km / 105km
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    if (meters < 100000) return '${(meters / 1000).toStringAsFixed(1)}km';
    return '${(meters / 1000).round()}km';
  }

  /// 指定範囲内か（デフォルト50km）
  static bool isWithinRange(double meters, {double maxMeters = 50000}) {
    return meters <= maxMeters;
  }
}
