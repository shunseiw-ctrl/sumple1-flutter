import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/activity_log_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late ActivityLogService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'worker-001'),
    );
    service = ActivityLogService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('ActivityLogService', () {
    test('logEvent がイベントドキュメントを作成する', () async {
      await service.logEvent(
        applicationId: 'app-001',
        eventType: 'status_change',
        description: 'ステータスが変更されました',
        metadata: {'oldStatus': 'applied', 'newStatus': 'assigned'},
      );

      final snap = await fakeFirestore
          .collection('applications')
          .doc('app-001')
          .collection('activity_logs')
          .get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['eventType'], 'status_change');
      expect(data['actorUid'], 'worker-001');
    });

    test('watchTimeline がタイムラインをストリームで返す', () async {
      await fakeFirestore
          .collection('applications')
          .doc('app-001')
          .collection('activity_logs')
          .add({
        'applicationId': 'app-001',
        'actorUid': 'worker-001',
        'actorRole': 'worker',
        'eventType': 'checkin',
        'description': '出勤しました',
        'createdAt': DateTime(2025, 4, 1),
      });

      final timeline = await service.watchTimeline('app-001').first;
      expect(timeline.length, 1);
      expect(timeline.first.eventType, 'checkin');
    });

    test('無効なeventTypeでArgumentError', () async {
      expect(
        () => service.logEvent(
          applicationId: 'app-001',
          eventType: 'invalid_type',
          description: 'テスト',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
