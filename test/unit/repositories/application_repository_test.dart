import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumple1/data/repositories/application_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ApplicationRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = ApplicationRepository(firestore: fakeFirestore);
  });

  group('ApplicationRepository', () {
    test('getPaginated returns empty when no applications', () async {
      final result = await repo.getPaginated(applicantUid: 'user1');

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.lastDocument, isNull);
    });

    test('getPaginated returns applications for applicantUid', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('applications').add({
          'applicantUid': 'user1',
          'adminUid': 'admin1',
          'jobId': 'job$i',
          'status': 'applied',
          'projectNameSnapshot': 'Project $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }
      // 別ユーザーの応募
      await fakeFirestore.collection('applications').add({
        'applicantUid': 'user2',
        'adminUid': 'admin1',
        'jobId': 'job99',
        'status': 'applied',
        'projectNameSnapshot': 'Other',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
      });

      final result = await repo.getPaginated(applicantUid: 'user1');

      expect(result.items.length, 5);
      expect(result.hasMore, isFalse);
    });

    test('getPaginated respects limit and hasMore', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('applications').add({
          'applicantUid': 'user1',
          'adminUid': 'admin1',
          'jobId': 'job$i',
          'status': 'applied',
          'projectNameSnapshot': 'Project $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final result = await repo.getPaginated(applicantUid: 'user1', limit: 3);

      expect(result.items.length, 3);
      expect(result.hasMore, isTrue);
      expect(result.lastDocument, isNotNull);
    });

    test('getPaginated supports cursor-based pagination', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('applications').add({
          'applicantUid': 'user1',
          'adminUid': 'admin1',
          'jobId': 'job$i',
          'status': 'applied',
          'projectNameSnapshot': 'Project $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final page1 = await repo.getPaginated(applicantUid: 'user1', limit: 3);
      final page2 = await repo.getPaginated(
        applicantUid: 'user1',
        limit: 3,
        startAfter: page1.lastDocument,
      );

      expect(page2.items.length, 2);
      expect(page2.hasMore, isFalse);
    });

    test('getPaginatedByAdmin returns applications for adminUid', () async {
      for (int i = 0; i < 3; i++) {
        await fakeFirestore.collection('applications').add({
          'applicantUid': 'user$i',
          'adminUid': 'admin1',
          'jobId': 'job$i',
          'status': 'applied',
          'projectNameSnapshot': 'Project $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final result = await repo.getPaginatedByAdmin(adminUid: 'admin1');

      expect(result.items.length, 3);
    });

    test('watchRecent returns stream', () async {
      for (int i = 0; i < 3; i++) {
        await fakeFirestore.collection('applications').add({
          'applicantUid': 'user1',
          'adminUid': 'admin1',
          'jobId': 'job$i',
          'status': 'applied',
          'projectNameSnapshot': 'Project $i',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1 + i)),
        });
      }

      final stream = repo.watchRecent(applicantUid: 'user1', limit: 2);
      final snapshot = await stream.first;

      expect(snapshot.docs.length, 2);
    });

    test('getPaginated orders by createdAt descending', () async {
      await fakeFirestore.collection('applications').add({
        'applicantUid': 'user1',
        'adminUid': 'admin1',
        'jobId': 'job1',
        'status': 'applied',
        'projectNameSnapshot': 'Old',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await fakeFirestore.collection('applications').add({
        'applicantUid': 'user1',
        'adminUid': 'admin1',
        'jobId': 'job2',
        'status': 'assigned',
        'projectNameSnapshot': 'New',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
      });

      final result = await repo.getPaginated(applicantUid: 'user1');

      expect(result.items.first.data()['projectNameSnapshot'], 'New');
    });
  });
}
