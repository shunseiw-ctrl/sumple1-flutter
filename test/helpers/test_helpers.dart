import 'package:flutter/material.dart';

/// テスト用MaterialAppラッパー
Widget buildTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

/// BuildContext取得用ヘルパー
Widget buildTestAppWithCallback(void Function(BuildContext) callback) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        callback(context);
        return const SizedBox.shrink();
      },
    ),
  );
}
