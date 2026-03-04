/// 円フォーマットユーティリティ
class CurrencyUtils {
  CurrencyUtils._();

  /// 整数を3桁区切り+¥プレフィックスでフォーマット
  /// 例: 15000 → "¥15,000"
  static String formatYen(int value) {
    final negative = value < 0;
    final abs = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < abs.length; i++) {
      final idxFromEnd = abs.length - i;
      buf.write(abs[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return '${negative ? '-' : ''}¥${buf.toString()}';
  }

  /// 整数を3桁区切りでフォーマット（¥プレフィックスなし）
  /// 例: 15000 → "15,000"
  static String formatNumber(int value) {
    final negative = value < 0;
    final abs = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < abs.length; i++) {
      final idxFromEnd = abs.length - i;
      buf.write(abs[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return '${negative ? '-' : ''}${buf.toString()}';
  }
}
