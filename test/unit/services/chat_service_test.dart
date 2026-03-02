import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/chat_service.dart';

void main() {
  group('ChatRoomInitResult', () {
    test('success factoryの全プロパティ', () {
      final result = ChatRoomInitResult.success(
        applicantUid: 'worker-001',
        adminUid: 'admin-001',
        jobId: 'job-001',
        titleSnapshot: 'テスト案件',
        isApplicant: true,
        isAdmin: false,
      );

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.applicantUid, 'worker-001');
      expect(result.adminUid, 'admin-001');
      expect(result.jobId, 'job-001');
      expect(result.titleSnapshot, 'テスト案件');
      expect(result.isApplicant, isTrue);
      expect(result.isAdmin, isFalse);
    });

    test('error factoryの全プロパティ', () {
      final result = ChatRoomInitResult.error('エラーメッセージ');

      expect(result.success, isFalse);
      expect(result.errorMessage, 'エラーメッセージ');
      expect(result.applicantUid, isNull);
      expect(result.adminUid, isNull);
      expect(result.isApplicant, isFalse);
      expect(result.isAdmin, isFalse);
    });
  });

  group('SendMessageResult', () {
    test('success factoryの全プロパティ', () {
      final result = SendMessageResult.success();

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('error factoryの全プロパティ', () {
      final result = SendMessageResult.error('送信失敗');

      expect(result.success, isFalse);
      expect(result.errorMessage, '送信失敗');
    });
  });

  group('ChatService with fake Firestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late ChatService chatService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'worker-001',
        email: 'worker@test.com',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      chatService = ChatService(firestore: fakeFirestore, auth: mockAuth);
    });

    group('initializeChatRoom', () {
      test('応募データが存在しない場合はエラー', () async {
        final result = await chatService.initializeChatRoom('non-existent');

        expect(result.success, isFalse);
        expect(result.errorMessage, '応募データが見つかりません');
      });

      test('権限のないユーザーはエラー', () async {
        await fakeFirestore.collection('applications').doc('app-001').set({
          'applicantUid': 'other-user',
          'adminUid': 'admin-001',
          'jobId': 'job-001',
          'projectNameSnapshot': 'テスト案件',
        });

        final result = await chatService.initializeChatRoom('app-001');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'このチャットを開く権限がありません');
      });

      test('応募者として正常に初期化できる', () async {
        await fakeFirestore.collection('applications').doc('app-001').set({
          'applicantUid': 'worker-001',
          'adminUid': 'admin-001',
          'jobId': 'job-001',
          'projectNameSnapshot': 'テスト案件',
        });

        final result = await chatService.initializeChatRoom('app-001');

        expect(result.success, isTrue);
        expect(result.isApplicant, isTrue);
        expect(result.isAdmin, isFalse);
        expect(result.applicantUid, 'worker-001');
        expect(result.titleSnapshot, 'テスト案件');
      });

      test('チャットドキュメントが自動作成される', () async {
        await fakeFirestore.collection('applications').doc('app-001').set({
          'applicantUid': 'worker-001',
          'adminUid': 'admin-001',
          'jobId': 'job-001',
          'projectNameSnapshot': 'テスト案件',
        });

        await chatService.initializeChatRoom('app-001');

        final chatDoc =
            await fakeFirestore.collection('chats').doc('app-001').get();
        expect(chatDoc.exists, isTrue);
        expect(chatDoc.data()?['applicantUid'], 'worker-001');
        expect(chatDoc.data()?['adminUid'], 'admin-001');
      });

      test('必要情報が不足している場合はエラー', () async {
        await fakeFirestore.collection('applications').doc('app-001').set({
          'applicantUid': 'worker-001',
          'adminUid': '',
          'jobId': 'job-001',
        });

        final result = await chatService.initializeChatRoom('app-001');
        expect(result.success, isFalse);
        expect(result.errorMessage, '必要情報が不足しています');
      });
    });

    group('sendMessage', () {
      test('空メッセージはエラー', () async {
        final result = await chatService.sendMessage(
          applicationId: 'app-001',
          text: '',
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, 'メッセージが空です');
      });

      test('空白のみのメッセージはエラー', () async {
        final result = await chatService.sendMessage(
          applicationId: 'app-001',
          text: '   ',
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, 'メッセージが空です');
      });

      test('正常にメッセージを送信できる', () async {
        // チャットと応募ドキュメントを準備
        await fakeFirestore.collection('applications').doc('app-001').set({
          'applicantUid': 'worker-001',
          'adminUid': 'admin-001',
          'jobId': 'job-001',
        });
        await fakeFirestore.collection('chats').doc('app-001').set({
          'applicantUid': 'worker-001',
          'adminUid': 'admin-001',
          'jobId': 'job-001',
          'titleSnapshot': 'テスト案件',
        });

        final result = await chatService.sendMessage(
          applicationId: 'app-001',
          text: 'こんにちは',
        );

        expect(result.success, isTrue);

        // メッセージが追加されていることを確認
        final messages = await fakeFirestore
            .collection('chats')
            .doc('app-001')
            .collection('messages')
            .get();
        expect(messages.docs.length, 1);
        expect(messages.docs.first.data()['text'], 'こんにちは');
        expect(messages.docs.first.data()['senderUid'], 'worker-001');
      });
    });
  });

  group('ChatService - 未ログイン', () {
    test('未ログインでinitializeChatRoomはエラー', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final chatService = ChatService(firestore: fakeFirestore, auth: mockAuth);

      final result = await chatService.initializeChatRoom('app-001');

      expect(result.success, isFalse);
      expect(result.errorMessage, 'ログインしてください');
    });

    test('未ログインでsendMessageはエラー', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final chatService = ChatService(firestore: fakeFirestore, auth: mockAuth);

      final result = await chatService.sendMessage(
        applicationId: 'app-001',
        text: 'テスト',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, 'ログインしてください');
    });
  });

  group('ChatService.sendImageMessage', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late ChatService chatService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'worker-001',
        email: 'worker@test.com',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      chatService = ChatService(firestore: fakeFirestore, auth: mockAuth);
    });

    test('空imageUrl→エラー', () async {
      final result = await chatService.sendImageMessage(
        applicationId: 'app-001',
        imageUrl: '',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, '画像URLが空です');
    });

    test('空白のみimageUrl→エラー', () async {
      final result = await chatService.sendImageMessage(
        applicationId: 'app-001',
        imageUrl: '   ',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, '画像URLが空です');
    });

    test('成功時にimageUrl・messageTypeがFirestoreに書き込まれる', () async {
      await fakeFirestore.collection('applications').doc('app-001').set({
        'applicantUid': 'worker-001',
        'adminUid': 'admin-001',
        'jobId': 'job-001',
      });
      await fakeFirestore.collection('chats').doc('app-001').set({
        'applicantUid': 'worker-001',
        'adminUid': 'admin-001',
        'jobId': 'job-001',
        'titleSnapshot': 'テスト案件',
      });

      final result = await chatService.sendImageMessage(
        applicationId: 'app-001',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(result.success, isTrue);

      final messages = await fakeFirestore
          .collection('chats')
          .doc('app-001')
          .collection('messages')
          .get();
      expect(messages.docs.length, 1);
      expect(messages.docs.first.data()['imageUrl'], 'https://example.com/image.jpg');
      expect(messages.docs.first.data()['messageType'], 'image');
      expect(messages.docs.first.data()['senderUid'], 'worker-001');

      // チャット情報更新も確認
      final chatDoc = await fakeFirestore.collection('chats').doc('app-001').get();
      expect(chatDoc.data()?['lastMessageText'], '[画像]');
    });
  });
}
