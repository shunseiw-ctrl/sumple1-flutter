import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/chat_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ChatService chatService;

  const workerUid = 'worker-001';
  const adminUid = 'admin-001';
  const applicationId = 'app-001';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();

    // テストデータ: chat
    await fakeFirestore.collection('chats').doc(applicationId).set(
      TestFixtures.chatData(
        applicationId: applicationId,
        applicantUid: workerUid,
        adminUid: adminUid,
      ),
    );
  });

  group('markAsRead', () {
    test('applicantのlastReadAtが更新される', () async {
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: workerUid),
        signedIn: true,
      );
      chatService = ChatService(
        firestore: fakeFirestore,
        auth: mockAuth,
        notificationService: NotificationService(firestore: fakeFirestore),
      );

      await chatService.markAsRead(
        applicationId: applicationId,
        isApplicant: true,
      );

      final chatDoc =
          await fakeFirestore.collection('chats').doc(applicationId).get();
      final data = chatDoc.data()!;
      expect(data.containsKey('lastReadAtApplicant'), isTrue);
    });

    test('adminのlastReadAtが更新される', () async {
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: adminUid),
        signedIn: true,
      );
      chatService = ChatService(
        firestore: fakeFirestore,
        auth: mockAuth,
        notificationService: NotificationService(firestore: fakeFirestore),
      );

      await chatService.markAsRead(
        applicationId: applicationId,
        isApplicant: false,
      );

      final chatDoc =
          await fakeFirestore.collection('chats').doc(applicationId).get();
      final data = chatDoc.data()!;
      expect(data.containsKey('lastReadAtAdmin'), isTrue);
    });

    test('相手のlastReadAtは変更しない', () async {
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: workerUid),
        signedIn: true,
      );
      chatService = ChatService(
        firestore: fakeFirestore,
        auth: mockAuth,
        notificationService: NotificationService(firestore: fakeFirestore),
      );

      await chatService.markAsRead(
        applicationId: applicationId,
        isApplicant: true,
      );

      final chatDoc =
          await fakeFirestore.collection('chats').doc(applicationId).get();
      final data = chatDoc.data()!;
      // applicantがmarkAsReadしたのでadminのは更新されない
      expect(data.containsKey('lastReadAtAdmin'), isFalse);
    });
  });
}
