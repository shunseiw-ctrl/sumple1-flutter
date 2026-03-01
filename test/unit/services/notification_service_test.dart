import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/notification_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late NotificationService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = NotificationService(firestore: fakeFirestore);
  });

  group('NotificationService.createNotification', () {
    test('creates a notification document', () async {
      await service.createNotification(
        targetUid: 'user123',
        title: 'テスト通知',
        body: '通知の内容です',
      );

      final snap = await fakeFirestore.collection('notifications').get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['targetUid'], 'user123');
      expect(data['title'], 'テスト通知');
      expect(data['body'], '通知の内容です');
      expect(data['type'], 'general');
      expect(data['read'], false);
    });

    test('creates notification with custom type and data', () async {
      await service.createNotification(
        targetUid: 'user123',
        title: '応募通知',
        body: '新しい応募がありました',
        type: 'application',
        data: {'jobId': 'job1'},
      );

      final snap = await fakeFirestore.collection('notifications').get();
      final data = snap.docs.first.data();
      expect(data['type'], 'application');
      expect(data['data'], {'jobId': 'job1'});
    });
  });

  group('NotificationService.unreadCountStream', () {
    test('returns 0 when no notifications', () async {
      final stream = service.unreadCountStream('user123');
      final count = await stream.first;
      expect(count, 0);
    });

    test('returns count of unread notifications', () async {
      await fakeFirestore.collection('notifications').add({
        'targetUid': 'user123',
        'title': 'Test',
        'body': 'Body',
        'read': false,
      });
      await fakeFirestore.collection('notifications').add({
        'targetUid': 'user123',
        'title': 'Test2',
        'body': 'Body2',
        'read': true,
      });

      final stream = service.unreadCountStream('user123');
      final count = await stream.first;
      expect(count, 1);
    });
  });

  group('NotificationService.markAsRead', () {
    test('marks a notification as read', () async {
      final ref = await fakeFirestore.collection('notifications').add({
        'targetUid': 'user123',
        'title': 'Test',
        'body': 'Body',
        'read': false,
      });

      await service.markAsRead(ref.id);

      final doc = await fakeFirestore.collection('notifications').doc(ref.id).get();
      expect(doc.data()!['read'], true);
    });
  });

  group('NotificationService.markAllAsRead', () {
    test('marks all unread notifications as read', () async {
      await fakeFirestore.collection('notifications').add({
        'targetUid': 'user123',
        'title': 'Test1',
        'body': 'Body1',
        'read': false,
      });
      await fakeFirestore.collection('notifications').add({
        'targetUid': 'user123',
        'title': 'Test2',
        'body': 'Body2',
        'read': false,
      });

      await service.markAllAsRead('user123');

      final snap = await fakeFirestore
          .collection('notifications')
          .where('targetUid', isEqualTo: 'user123')
          .get();
      for (final doc in snap.docs) {
        expect(doc.data()['read'], true);
      }
    });
  });
}
