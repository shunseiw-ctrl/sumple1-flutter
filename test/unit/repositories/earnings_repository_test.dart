import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumple1/data/repositories/earnings_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late EarningsRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = EarningsRepository(firestore: fakeFirestore);
  });

  group('EarningsRepository', () {
    test('getPaginated returns empty when no earnings', () async {
      final result = await repo.getPaginated(uid: 'user1');

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.lastDocument, isNull);
    });

    test('getPaginated returns earnings for uid', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('earnings').add({
          'uid': 'user1',
          'amount': 10000 + i * 1000,
          'applicationId': 'app$i',
          'projectNameSnapshot': 'Project $i',
          'payoutConfirmedAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }
      // 別ユーザーの売上
      await fakeFirestore.collection('earnings').add({
        'uid': 'user2',
        'amount': 50000,
        'applicationId': 'app99',
        'projectNameSnapshot': 'Other',
        'payoutConfirmedAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
      });

      final result = await repo.getPaginated(uid: 'user1');

      expect(result.items.length, 5);
      expect(result.hasMore, isFalse);
    });

    test('getPaginated respects limit and hasMore', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('earnings').add({
          'uid': 'user1',
          'amount': 10000 + i * 1000,
          'applicationId': 'app$i',
          'projectNameSnapshot': 'Project $i',
          'payoutConfirmedAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final result = await repo.getPaginated(uid: 'user1', limit: 3);

      expect(result.items.length, 3);
      expect(result.hasMore, isTrue);
      expect(result.lastDocument, isNotNull);
    });

    test('getPaginated supports cursor-based pagination', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('earnings').add({
          'uid': 'user1',
          'amount': 10000 + i * 1000,
          'applicationId': 'app$i',
          'projectNameSnapshot': 'Project $i',
          'payoutConfirmedAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final page1 = await repo.getPaginated(uid: 'user1', limit: 3);
      final page2 = await repo.getPaginated(
        uid: 'user1',
        limit: 3,
        startAfter: page1.lastDocument,
      );

      expect(page2.items.length, 2);
      expect(page2.hasMore, isFalse);
    });

    test('getPaginatedAll returns all earnings with pagination', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('earnings').add({
          'uid': 'user$i',
          'amount': 10000 + i * 1000,
          'applicationId': 'app$i',
          'projectNameSnapshot': 'Project $i',
          'payoutConfirmedAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final result = await repo.getPaginatedAll(limit: 3);

      expect(result.items.length, 3);
      expect(result.hasMore, isTrue);
    });

    test('watchRecent returns stream', () async {
      for (int i = 0; i < 3; i++) {
        await fakeFirestore.collection('earnings').add({
          'uid': 'user1',
          'amount': 10000 + i * 1000,
          'applicationId': 'app$i',
          'projectNameSnapshot': 'Project $i',
          'payoutConfirmedAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final stream = repo.watchRecent(uid: 'user1', limit: 2);
      final snapshot = await stream.first;

      expect(snapshot.docs.length, 2);
    });

    test('getPaginated orders by payoutConfirmedAt descending', () async {
      await fakeFirestore.collection('earnings').add({
        'uid': 'user1',
        'amount': 10000,
        'applicationId': 'app1',
        'projectNameSnapshot': 'Old',
        'payoutConfirmedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await fakeFirestore.collection('earnings').add({
        'uid': 'user1',
        'amount': 20000,
        'applicationId': 'app2',
        'projectNameSnapshot': 'New',
        'payoutConfirmedAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
      });

      final result = await repo.getPaginated(uid: 'user1');

      expect(result.items.first.data()['projectNameSnapshot'], 'New');
    });
  });
}
