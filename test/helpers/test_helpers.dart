import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Riverpod付きテストアプリ
Widget buildTestAppWithRiverpod(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// GoRouter付きテストアプリ
Widget buildTestAppWithRouter(Widget child) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => child),
      ]),
    ),
  );
}
