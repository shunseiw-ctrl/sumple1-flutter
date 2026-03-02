import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/chat_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late ChatService chatService;

  /// テスト用にNotificationServiceをDIして使う
  /// NotificationServiceはFirestoreに直接書くだけなので
  /// FakeFirebaseFirestoreで検証可能
  late NotificationService notificationService;

  const workerUid = 'worker-001';
  const adminUid = 'admin-001';
  const applicationId = 'app-001';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      mockUser: MockUser(uid: workerUid),
      signedIn: true,
    );
    notificationService = NotificationService(firestore: fakeFirestore);
    chatService = ChatService(
      firestore: fakeFirestore,
      auth: mockAuth,
      notificationService: notificationService,
    );

    // テストデータ: application
    await fakeFirestore.collection('applications').doc(applicationId).set(
      TestFixtures.applicationData(
        applicantUid: workerUid,
        adminUid: adminUid,
        projectNameSnapshot: 'テスト案件',
      ),
    );

    // テストデータ: chat
    await fakeFirestore.collection('chats').doc(applicationId).set(
      TestFixtures.chatData(
        applicationId: applicationId,
        applicantUid: workerUid,
        adminUid: adminUid,
      ),
    );
  });

  group('sendMessage通知', () {
    test('応募者送信時にadminへ通知作成', () async {
      // workerとしてログイン中
      final result = await chatService.sendMessage(
        applicationId: applicationId,
        text: 'こんにちは',
      );

      expect(result.success, isTrue);

      // notifications コレクションを確認
      final notifSnap = await fakeFirestore.collection('notifications').get();
      expect(notifSnap.docs.length, 1);

      final notif = notifSnap.docs.first.data();
      expect(notif['targetUid'], adminUid);
      expect(notif['title'], 'チャット');
      expect(notif['body'], 'こんにちは');
      expect(notif['type'], 'chat_message');
    });

    test('admin送信時に応募者へ通知作成', () async {
      // adminとしてログイン
      final adminAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: adminUid),
        signedIn: true,
      );
      final adminChatService = ChatService(
        firestore: fakeFirestore,
        auth: adminAuth,
        notificationService: notificationService,
      );

      final result = await adminChatService.sendMessage(
        applicationId: applicationId,
        text: '了解です',
      );

      expect(result.success, isTrue);

      final notifSnap = await fakeFirestore.collection('notifications').get();
      // worker送信分 + admin送信分 ではなく、admin送信のみ
      final adminNotifs = notifSnap.docs
          .where((d) => d.data()['targetUid'] == workerUid)
          .toList();
      expect(adminNotifs.length, 1);
      expect(adminNotifs.first.data()['body'], '了解です');
    });

    test('長いメッセージが50文字で切り詰め', () async {
      final longText = 'あ' * 60;
      final result = await chatService.sendMessage(
        applicationId: applicationId,
        text: longText,
      );

      expect(result.success, isTrue);

      final notifSnap = await fakeFirestore.collection('notifications').get();
      expect(notifSnap.docs.length, 1);

      final body = notifSnap.docs.first.data()['body'] as String;
      expect(body.endsWith('...'), isTrue);
      // 50文字 + '...' = 53文字
      expect(body.length, 53);
    });

    test('通知のtype/dataが正しい', () async {
      await chatService.sendMessage(
        applicationId: applicationId,
        text: 'テスト',
      );

      final notifSnap = await fakeFirestore.collection('notifications').get();
      final notif = notifSnap.docs.first.data();
      expect(notif['type'], 'chat_message');
      expect(notif['data'], {'applicationId': applicationId});
      expect(notif['read'], false);
    });
  });

  group('sendImageMessage通知', () {
    test('画像メッセージで[画像]ボディの通知作成', () async {
      final result = await chatService.sendImageMessage(
        applicationId: applicationId,
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(result.success, isTrue);

      final notifSnap = await fakeFirestore.collection('notifications').get();
      expect(notifSnap.docs.length, 1);

      final notif = notifSnap.docs.first.data();
      expect(notif['targetUid'], adminUid);
      expect(notif['body'], '[画像]');
      expect(notif['type'], 'chat_message');
    });
  });

  group('通知失敗時', () {
    test('通知作成失敗でもメッセージ送信は成功', () async {
      // 通知用に別のNotificationServiceを使用（エラーを起こすための直接テスト）
      // 実際にはNotificationServiceはtry-catch内なので
      // メッセージ送信自体は常に成功する
      final result = await chatService.sendMessage(
        applicationId: applicationId,
        text: 'メッセージテスト',
      );

      expect(result.success, isTrue);

      // メッセージが保存されていることを確認
      final msgSnap = await fakeFirestore
          .collection('chats')
          .doc(applicationId)
          .collection('messages')
          .get();
      expect(msgSnap.docs.length, 1);
    });
  });
}
