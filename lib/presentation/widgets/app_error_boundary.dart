import 'package:flutter/material.dart';

/// アプリ全体のエラー境界ウィジェット。
///
/// FlutterError.onError は main.dart で Crashlytics に設定済み。
/// このウィジェットはグローバル状態を上書きせず、子ウィジェットをそのまま返す。
class AppErrorBoundary extends StatelessWidget {
  final Widget child;
  const AppErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
