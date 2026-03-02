/// DateTime を 'YYYY-MM-DD' 形式の文字列に変換する
String dateKey(DateTime d) {
  final y = d.year.toString();
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// 'YYYY-MM-DD' から 'YYYY-MM' を取得する
String monthKeyFromDateKey(String dateKey) {
  if (dateKey.length >= 7) return dateKey.substring(0, 7);
  return '';
}
