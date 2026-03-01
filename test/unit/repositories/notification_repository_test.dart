import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumple1/data/repositories/notification_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late NotificationRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = NotificationRepository(firestore: fakeFirestore);
  });

  group('NotificationRepository', () {
    test('getPaginated returns empty when no notifications', () async {
      final result = await repo.getPaginated(targetUid: 'user1');

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.lastDocument, isNull);
    });

    test('getPaginated returns notifications for targetUid', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('notifications').add({
          'targetUid': 'user1',
          'title': 'Notification $i',
          'body': 'Body $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }
      // 別ユーザーの通知
      await fakeFirestore.collection('notifications').add({
        'targetUid': 'user2',
        'title': 'Other notification',
        'body': 'Other body',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
      });

      final result = await repo.getPaginated(targetUid: 'user1');

      expect(result.items.length, 5);
      expect(result.hasMore, isFalse);
    });

    test('getPaginated respects limit', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('notifications').add({
          'targetUid': 'user1',
          'title': 'Notification $i',
          'body': 'Body $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final result = await repo.getPaginated(targetUid: 'user1', limit: 3);

      expect(result.items.length, 3);
      expect(result.hasMore, isTrue);
      expect(result.lastDocument, isNotNull);
    });

    test('getPaginated supports cursor-based pagination', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('notifications').add({
          'targetUid': 'user1',
          'title': 'Notification $i',
          'body': 'Body $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final page1 = await repo.getPaginated(targetUid: 'user1', limit: 3);
      expect(page1.items.length, 3);
      expect(page1.hasMore, isTrue);

      final page2 = await repo.getPaginated(
        targetUid: 'user1',
        limit: 3,
        startAfter: page1.lastDocument,
      );
      expect(page2.items.length, 2);
      expect(page2.hasMore, isFalse);
    });

    test('watchRecent returns stream with limit', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('notifications').add({
          'targetUid': 'user1',
          'title': 'Notification $i',
          'body': 'Body $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final stream = repo.watchRecent(targetUid: 'user1', limit: 3);
      final snapshot = await stream.first;

      expect(snapshot.docs.length, 3);
    });

    test('getPaginated orders by createdAt descending', () async {
      await fakeFirestore.collection('notifications').add({
        'targetUid': 'user1',
        'title': 'Old',
        'body': 'Old body',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await fakeFirestore.collection('notifications').add({
        'targetUid': 'user1',
        'title': 'New',
        'body': 'New body',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
      });

      final result = await repo.getPaginated(targetUid: 'user1');

      expect(result.items.first.data()['title'], 'New');
      expect(result.items.last.data()['title'], 'Old');
    });
  });
}
