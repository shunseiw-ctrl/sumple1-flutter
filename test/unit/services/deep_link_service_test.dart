import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    late DeepLinkService service;

    setUp(() {
      // AppLinks は実際のプラットフォームチャネルが必要なため、
      // parseUri / parseNotificationData のロジックテストに集中
      service = DeepLinkService();
    });

    group('parseUri', () {
      test('jobs/{jobId} パスを解析できる', () {
        final uri = Uri.parse('https://albawork.app/jobs/job123');
        final route = service.parseUri(uri);

        expect(route, isNotNull);
        expect(route!.path, '/jobs/detail');
        expect(route.params['jobId'], 'job123');
      });

      test('jobs パスのみの場合は一覧ルート', () {
        final uri = Uri.parse('https://albawork.app/jobs');
        final route = service.parseUri(uri);

        expect(route, isNotNull);
        expect(route!.path, '/jobs');
      });

      test('chat/{chatId} パスを解析できる', () {
        final uri = Uri.parse('https://albawork.app/chat/chat456');
        final route = service.parseUri(uri);

        expect(route, isNotNull);
        expect(route!.path, '/chat/room');
        expect(route.params['chatId'], 'chat456');
      });

      test('notifications パスを解析できる', () {
        final uri = Uri.parse('https://albawork.app/notifications');
        final route = service.parseUri(uri);

        expect(route, isNotNull);
        expect(route!.path, '/notifications');
      });

      test('profile パスを解析できる', () {
        final uri = Uri.parse('https://albawork.app/profile');
        final route = service.parseUri(uri);

        expect(route, isNotNull);
        expect(route!.path, '/profile');
      });

      test('不明なパスではnullを返す', () {
        final uri = Uri.parse('https://albawork.app/unknown/path');
        final route = service.parseUri(uri);

        expect(route, isNull);
      });

      test('空パスではnullを返す', () {
        final uri = Uri.parse('https://albawork.app/');
        final route = service.parseUri(uri);

        expect(route, isNull);
      });

      test('カスタムスキームでもパース可能', () {
        final uri = Uri.parse('albawork://open/jobs/job789');
        final route = service.parseUri(uri);

        expect(route, isNotNull);
        expect(route!.path, '/jobs/detail');
        expect(route.params['jobId'], 'job789');
      });

      test('chat パスのみ (chatIdなし) ではnullを返す', () {
        final uri = Uri.parse('https://albawork.app/chat');
        final route = service.parseUri(uri);

        expect(route, isNull);
      });
    });

    group('parseNotificationData', () {
      test('job_posted タイプで正しいルート返却', () {
        final route = service.parseNotificationData({
          'type': 'job_posted',
          'jobId': 'job123',
        });

        expect(route, isNotNull);
        expect(route!.path, '/jobs/detail');
        expect(route.params['jobId'], 'job123');
      });

      test('chat_message タイプで正しいルート返却', () {
        final route = service.parseNotificationData({
          'type': 'chat_message',
          'chatId': 'chat456',
        });

        expect(route, isNotNull);
        expect(route!.path, '/chat/room');
        expect(route.params['chatId'], 'chat456');
      });

      test('application_update タイプで通知ページ', () {
        final route = service.parseNotificationData({
          'type': 'application_update',
        });

        expect(route, isNotNull);
        expect(route!.path, '/notifications');
      });

      test('earning_confirmed タイプで通知ページ', () {
        final route = service.parseNotificationData({
          'type': 'earning_confirmed',
          'earningId': 'earn123',
        });

        expect(route, isNotNull);
        expect(route!.path, '/notifications');
      });

      test('未知のタイプではnullを返す', () {
        final route = service.parseNotificationData({
          'type': 'unknown_type',
        });

        expect(route, isNull);
      });

      test('typeがない場合はnullを返す', () {
        final route = service.parseNotificationData({
          'jobId': 'job123',
        });

        expect(route, isNull);
      });

      test('job_posted でjobIdが空の場合はnullを返す', () {
        final route = service.parseNotificationData({
          'type': 'job_posted',
          'jobId': '',
        });

        expect(route, isNull);
      });
    });

    group('goRouterPath', () {
      test('jobs/{jobId} URI を go_router パスに変換', () {
        final uri = Uri.parse('https://albawork.app/jobs/job123');
        final path = service.goRouterPath(uri);

        expect(path, '/jobs/job123');
      });

      test('jobs URI を一覧パスに変換', () {
        final uri = Uri.parse('https://albawork.app/jobs');
        final path = service.goRouterPath(uri);

        expect(path, '/jobs');
      });

      test('chat/{chatId} URI を go_router パスに変換', () {
        final uri = Uri.parse('https://albawork.app/chat/chat456');
        final path = service.goRouterPath(uri);

        expect(path, '/chat/chat456');
      });

      test('notifications URI を go_router パスに変換', () {
        final uri = Uri.parse('https://albawork.app/notifications');
        final path = service.goRouterPath(uri);

        expect(path, '/notifications');
      });

      test('profile URI を go_router パスに変換', () {
        final uri = Uri.parse('https://albawork.app/profile');
        final path = service.goRouterPath(uri);

        expect(path, '/profile');
      });

      test('不明な URI ではnullを返す', () {
        final uri = Uri.parse('https://albawork.app/unknown');
        final path = service.goRouterPath(uri);

        expect(path, isNull);
      });
    });

    group('goRouterPathFromNotification', () {
      test('job_posted 通知を go_router パスに変換', () {
        final path = service.goRouterPathFromNotification({
          'type': 'job_posted',
          'jobId': 'job123',
        });

        expect(path, '/jobs/job123');
      });

      test('chat_message 通知を go_router パスに変換', () {
        final path = service.goRouterPathFromNotification({
          'type': 'chat_message',
          'chatId': 'chat456',
        });

        expect(path, '/chat/chat456');
      });

      test('application_update 通知を go_router パスに変換', () {
        final path = service.goRouterPathFromNotification({
          'type': 'application_update',
        });

        expect(path, '/notifications');
      });

      test('未知のタイプではnullを返す', () {
        final path = service.goRouterPathFromNotification({
          'type': 'unknown',
        });

        expect(path, isNull);
      });
    });
  });
}
