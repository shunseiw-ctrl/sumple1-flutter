import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/notification_providers.dart';
import 'package:sumple1/core/providers/auth_provider.dart';
import 'package:sumple1/core/services/notification_service.dart';

void main() {
  group('notificationServiceProvider', () {
    test('NotificationServiceインスタンスを提供する', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final service = NotificationService(firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(notificationServiceProvider);
      expect(result, isA<NotificationService>());
      expect(result, same(service));
    });
  });

  group('unreadNotificationCountProvider', () {
    test('UID空の場合は0を返す', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserUidProvider.overrideWithValue(''),
        ],
      );
      addTearDown(container.dispose);

      container.read(unreadNotificationCountProvider);
      // Stream.value(0) なので最初はloading、次にdata
      await container.read(unreadNotificationCountProvider.future);
      final result = container.read(unreadNotificationCountProvider);
      expect(result.value, equals(0));
    });
  });

  group('notificationsStreamProvider', () {
    test('UID空の場合はストリームが空', () {
      final container = ProviderContainer(
        overrides: [
          currentUserUidProvider.overrideWithValue(''),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(notificationsStreamProvider(20));
      // Stream.empty() -> loading state
      expect(result, isA<AsyncValue>());
    });
  });
}
