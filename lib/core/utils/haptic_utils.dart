import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  /// ボタンタップ、お気に入りトグル
  static void tap() => HapticFeedback.lightImpact();

  /// 成功アクション（応募完了、投稿完了等）
  static void success() => HapticFeedback.mediumImpact();

  /// チップ/タブ切替
  static void selection() => HapticFeedback.selectionClick();

  /// 削除操作の確認
  static void warning() => HapticFeedback.heavyImpact();
}
