import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../utils/logger.dart';
import '../router/route_paths.dart';
import 'line_auth_service.dart';

/// Deep Link ルート情報
class DeepLinkRoute {
  const DeepLinkRoute({required this.path, this.params = const {}});

  final String path;
  final Map<String, String> params;
}

class DeepLinkService {
  DeepLinkService({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<Uri>? _subscription;

  /// ナビゲーターキーを設定してリンクリスナーを開始
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;

    // アプリがリンクから起動された場合の初回処理
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        // Firebase Auth コールバックはSDKが自動処理するのでスキップ
        if (uri.scheme.startsWith('com.googleusercontent.apps')) {
          Logger.info('Firebase Auth initial link, skipping',
              tag: 'DeepLinkService');
          return;
        }
        _handleUri(uri);
      }
    });

    // アプリ実行中のリンク受信
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (error) {
        Logger.error('Deep link stream error',
            tag: 'DeepLinkService', error: error);
      },
    );

    Logger.info('DeepLinkService initialized', tag: 'DeepLinkService');
  }

  /// URI からルートを解析
  DeepLinkRoute? parseUri(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return null;

    switch (segments[0]) {
      case 'jobs':
        if (segments.length >= 2 && segments[1].isNotEmpty) {
          return DeepLinkRoute(
            path: '/jobs/detail',
            params: {'jobId': segments[1]},
          );
        }
        return const DeepLinkRoute(path: '/jobs');
      case 'chat':
        if (segments.length >= 2 && segments[1].isNotEmpty) {
          return DeepLinkRoute(
            path: '/chat/room',
            params: {'chatId': segments[1]},
          );
        }
        return null;
      case 'notifications':
        return const DeepLinkRoute(path: '/notifications');
      case 'profile':
        return const DeepLinkRoute(path: '/profile');
      case 'line-callback':
        // LINE OAuthコールバック — _handleUri で直接処理するため null 返却
        return null;
      default:
        Logger.warning('Unknown deep link path: ${uri.path}',
            tag: 'DeepLinkService');
        return null;
    }
  }

  /// 通知データからルーティング
  DeepLinkRoute? parseNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'job_posted':
        final jobId = data['jobId'] as String?;
        if (jobId != null && jobId.isNotEmpty) {
          return DeepLinkRoute(
            path: '/jobs/detail',
            params: {'jobId': jobId},
          );
        }
        return null;
      case 'chat_message':
        final chatId = data['chatId'] as String?;
        if (chatId != null && chatId.isNotEmpty) {
          return DeepLinkRoute(
            path: '/chat/room',
            params: {'chatId': chatId},
          );
        }
        return null;
      case 'application_update':
        return const DeepLinkRoute(path: '/notifications');
      case 'earning_confirmed':
        return const DeepLinkRoute(path: '/notifications');
      default:
        return null;
    }
  }

  /// URI を go_router パスに変換
  String? goRouterPath(Uri uri) {
    final route = parseUri(uri);
    if (route == null) return null;

    switch (route.path) {
      case '/jobs/detail':
        final jobId = route.params['jobId'];
        if (jobId != null && jobId.isNotEmpty) {
          return RoutePaths.jobDetailPath(jobId);
        }
        return RoutePaths.jobList;
      case '/jobs':
        return RoutePaths.jobList;
      case '/chat/room':
        final chatId = route.params['chatId'];
        if (chatId != null && chatId.isNotEmpty) {
          return RoutePaths.chatRoomPath(chatId);
        }
        return null;
      case '/notifications':
        return RoutePaths.notifications;
      case '/profile':
        return RoutePaths.profile;
      default:
        return null;
    }
  }

  /// 通知データを go_router パスに変換
  String? goRouterPathFromNotification(Map<String, dynamic> data) {
    final route = parseNotificationData(data);
    if (route == null) return null;

    switch (route.path) {
      case '/jobs/detail':
        final jobId = route.params['jobId'];
        if (jobId != null && jobId.isNotEmpty) {
          return RoutePaths.jobDetailPath(jobId);
        }
        return null;
      case '/chat/room':
        final chatId = route.params['chatId'];
        if (chatId != null && chatId.isNotEmpty) {
          return RoutePaths.chatRoomPath(chatId);
        }
        return null;
      case '/notifications':
        return RoutePaths.notifications;
      default:
        return null;
    }
  }

  void _handleUri(Uri uri) {
    Logger.info('Deep link received: $uri', tag: 'DeepLinkService');

    // Firebase Auth コールバック（reCAPTCHA等）はSDKに委譲してスキップ
    if (uri.scheme.startsWith('com.googleusercontent.apps')) {
      Logger.info('Firebase Auth callback, skipping', tag: 'DeepLinkService');
      return;
    }

    // LINE OAuth モバイルコールバック処理
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty && segments[0] == 'line-callback') {
      Logger.info('LINE mobile callback detected', tag: 'DeepLinkService');
      LineAuthService().handleMobileLineCallback(uri);
      return;
    }

    final route = parseUri(uri);
    if (route != null) {
      _navigateTo(route);
    }
  }

  void _navigateTo(DeepLinkRoute route) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      Logger.warning('Navigator not available for deep link',
          tag: 'DeepLinkService');
      return;
    }

    Logger.info('Navigating to: ${route.path}',
        tag: 'DeepLinkService', data: route.params);
    // ルーティングはアプリのページ構成に依存するため、
    // ここでは named route push のみ行う
    navigator.pushNamed(route.path, arguments: route.params);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
