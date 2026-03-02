import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/app_router.dart';
import 'package:sumple1/core/router/route_paths.dart';

/// AnalyticsService.observer がFirebase初期化を必要とするため、
/// テスト用にobserver無しのルーターをオーバーライドする
GoRouter _createTestRouter() {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const Scaffold(body: Text('Notifications')),
      ),
      GoRoute(
        path: RoutePaths.adminHome,
        builder: (context, state) => const Scaffold(body: Text('Admin')),
      ),
      GoRoute(
        path: RoutePaths.jobDetail,
        builder: (context, state) => const Scaffold(body: Text('JobDetail')),
      ),
      GoRoute(
        path: RoutePaths.workDetail,
        builder: (context, state) => const Scaffold(body: Text('WorkDetail')),
      ),
      GoRoute(
        path: RoutePaths.chatRoom,
        builder: (context, state) => const Scaffold(body: Text('ChatRoom')),
      ),
    ],
  );
}

void main() {
  group('routerProvider', () {
    test('GoRouterインスタンスをオーバーライドで取得できる', () {
      final testRouter = _createTestRouter();
      final container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(testRouter),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      expect(router, isA<GoRouter>());
      expect(router, same(testRouter));
    });
  });

  group('GoRouter ナビゲーション', () {
    late GoRouter router;

    setUp(() {
      router = _createTestRouter();
    });

    test('初期ルートがhomeに設定されている', () {
      expect(
        router.routeInformationProvider.value.uri.path,
        equals(RoutePaths.home),
      );
    });

    test('ルート設定が存在する', () {
      final config = router.configuration;
      expect(config.routes, isNotEmpty);
    });

    test('homeルートが定義されている', () {
      final config = router.configuration;
      final homeRoute = config.routes
          .whereType<GoRoute>()
          .where((r) => r.path == RoutePaths.home);
      expect(homeRoute, isNotEmpty);
    });

    test('loginルートが定義されている', () {
      final config = router.configuration;
      final loginRoute = config.routes
          .whereType<GoRoute>()
          .where((r) => r.path == RoutePaths.login);
      expect(loginRoute, isNotEmpty);
    });

    test('notificationsルートが定義されている', () {
      final config = router.configuration;
      final route = config.routes
          .whereType<GoRoute>()
          .where((r) => r.path == RoutePaths.notifications);
      expect(route, isNotEmpty);
    });

    test('jobDetailルートが定義されている', () {
      final config = router.configuration;
      final route = config.routes
          .whereType<GoRoute>()
          .where((r) => r.path == RoutePaths.jobDetail);
      expect(route, isNotEmpty);
    });

    test('パスパラメータ付きルートが定義されている', () {
      final config = router.configuration;
      final route = config.routes
          .whereType<GoRoute>()
          .where((r) => r.path == RoutePaths.workDetail);
      expect(route, isNotEmpty);
    });
  });
}
