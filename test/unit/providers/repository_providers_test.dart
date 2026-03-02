import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/repository_providers.dart';
import 'package:sumple1/data/repositories/job_repository.dart';
import 'package:sumple1/data/repositories/application_repository.dart';
import 'package:sumple1/data/repositories/notification_repository.dart';
import 'package:sumple1/data/repositories/earnings_repository.dart';

void main() {
  group('Repository Providers', () {
    test('jobRepositoryProviderがオーバーライドで動作する', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final repo = JobRepository(firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          jobRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(jobRepositoryProvider);
      expect(result, isA<JobRepository>());
      expect(result, same(repo));
    });

    test('applicationRepositoryProviderがオーバーライドで動作する', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final repo = ApplicationRepository(firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          applicationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(applicationRepositoryProvider);
      expect(result, isA<ApplicationRepository>());
      expect(result, same(repo));
    });

    test('notificationRepositoryProviderがオーバーライドで動作する', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final repo = NotificationRepository(firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(notificationRepositoryProvider);
      expect(result, isA<NotificationRepository>());
      expect(result, same(repo));
    });

    test('earningsRepositoryProviderがオーバーライドで動作する', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final repo = EarningsRepository(firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          earningsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(earningsRepositoryProvider);
      expect(result, isA<EarningsRepository>());
      expect(result, same(repo));
    });
  });
}
