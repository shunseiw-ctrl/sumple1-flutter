import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/chat_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/quality_score_service.dart';
import 'package:sumple1/core/services/phone_auth_service.dart';
import 'package:sumple1/data/models/early_payment_request_model.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('Phase 17 結合テスト', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('チャット送信→通知ドキュメント作成確認', () async {
      const workerUid = 'worker-001';
      const adminUid = 'admin-001';
      const applicationId = 'app-001';

      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: workerUid),
        signedIn: true,
      );
      final notifService = NotificationService(firestore: fakeFirestore);
      final chatService = ChatService(
        firestore: fakeFirestore,
        auth: mockAuth,
        notificationService: notifService,
      );

      await fakeFirestore.collection('applications').doc(applicationId).set(
        TestFixtures.applicationData(
          applicantUid: workerUid,
          adminUid: adminUid,
        ),
      );
      await fakeFirestore.collection('chats').doc(applicationId).set(
        TestFixtures.chatData(
          applicationId: applicationId,
          applicantUid: workerUid,
          adminUid: adminUid,
        ),
      );

      final result = await chatService.sendMessage(
        applicationId: applicationId,
        text: '結合テストメッセージ',
      );

      expect(result.success, isTrue);

      final notifs = await fakeFirestore.collection('notifications').get();
      expect(notifs.docs.length, 1);
      expect(notifs.docs.first.data()['targetUid'], adminUid);
      expect(notifs.docs.first.data()['type'], 'chat_message');
    });

    test('チャット既読→lastReadAt更新確認', () async {
      const workerUid = 'worker-001';
      const adminUid = 'admin-001';
      const applicationId = 'app-002';

      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: workerUid),
        signedIn: true,
      );
      final chatService = ChatService(
        firestore: fakeFirestore,
        auth: mockAuth,
        notificationService: NotificationService(firestore: fakeFirestore),
      );

      await fakeFirestore.collection('chats').doc(applicationId).set(
        TestFixtures.chatData(
          applicationId: applicationId,
          applicantUid: workerUid,
          adminUid: adminUid,
        ),
      );

      await chatService.markAsRead(
        applicationId: applicationId,
        isApplicant: true,
      );

      final chatDoc =
          await fakeFirestore.collection('chats').doc(applicationId).get();
      expect(chatDoc.data()!.containsKey('lastReadAtApplicant'), isTrue);
    });

    test('earnings作成→月次明細の自動反映（ロジック検証）', () async {
      // Cloud Functionのロジックを再現してテスト
      const workerUid = 'worker-001';
      const month = '2025-04';

      // 最初のearning
      final newItem1 = {
        'applicationId': 'app-001',
        'jobTitle': '内装工事',
        'completedDate': '2025-04-15',
        'amount': 50000,
      };

      await fakeFirestore.collection('monthly_statements').add({
        'workerUid': workerUid,
        'month': month,
        'items': [newItem1],
        'totalAmount': 50000,
        'netAmount': 50000,
        'status': 'draft',
        'paymentDate': '2025-05-10',
        'earlyPaymentRequested': false,
      });

      // 2つ目のearning追加（CFロジックの再現）
      final stmtQuery = await fakeFirestore
          .collection('monthly_statements')
          .where('workerUid', isEqualTo: workerUid)
          .where('month', isEqualTo: month)
          .get();

      expect(stmtQuery.docs.length, 1);

      final existingDoc = stmtQuery.docs.first;
      final existingData = existingDoc.data();
      final items = List<Map<String, dynamic>>.from(existingData['items'] ?? []);
      items.add({
        'applicationId': 'app-002',
        'jobTitle': '外壁工事',
        'completedDate': '2025-04-20',
        'amount': 30000,
      });
      final totalAmount = items.fold<int>(
          0, (acc, item) => acc + ((item['amount'] as int?) ?? 0));

      await existingDoc.reference.update({
        'items': items,
        'totalAmount': totalAmount,
        'netAmount': totalAmount,
      });

      final updatedDoc = await existingDoc.reference.get();
      expect(updatedDoc.data()!['totalAmount'], 80000);
      expect((updatedDoc.data()!['items'] as List).length, 2);
    });

    test('即金申請→手数料計算→承認フロー', () async {
      const requestedAmount = 150000;
      final fee = EarlyPaymentRequestModel.calculateFee(requestedAmount);
      final payout = EarlyPaymentRequestModel.calculatePayout(requestedAmount);

      expect(fee, 15000); // 10%
      expect(payout, 135000); // 90%

      // 申請作成
      final requestRef =
          await fakeFirestore.collection('early_payment_requests').add({
        'workerUid': 'worker-001',
        'statementId': 'stmt-001',
        'month': '2025-04',
        'requestedAmount': requestedAmount,
        'earlyPaymentFee': fee,
        'payoutAmount': payout,
        'status': 'requested',
      });

      // 承認
      await requestRef.update({
        'status': 'approved',
        'reviewedBy': 'admin-001',
      });

      final approvedDoc = await requestRef.get();
      expect(approvedDoc.data()!['status'], 'approved');
      expect(approvedDoc.data()!['reviewedBy'], 'admin-001');
    });

    test('品質スコア→UI表示データ整合性', () async {
      const workerUid = 'worker-score-test';

      // 評価データ
      await fakeFirestore.collection('ratings').add({
        'targetUid': workerUid,
        'stars': 5,
      });
      await fakeFirestore.collection('ratings').add({
        'targetUid': workerUid,
        'stars': 4,
      });

      // 応募データ
      for (final status in ['done', 'done', 'assigned']) {
        await fakeFirestore.collection('applications').add({
          'applicantUid': workerUid,
          'status': status,
        });
      }

      // 資格データ
      await fakeFirestore
          .collection('profiles')
          .doc(workerUid)
          .collection('qualifications_v2')
          .add({
        'verificationStatus': 'approved',
        'name': '足場組立',
      });

      final service = QualityScoreService(firestore: fakeFirestore);
      final score = await service.calculateScore(workerUid);

      expect(score.ratingsAverage, 4.5);
      expect(score.ratingsCount, 2);
      expect(score.totalCompleted, 2);
      expect(score.totalAssigned, 3);
      expect(score.verifiedQualificationCount, 1);
      expect(score.overallScore, greaterThan(0));
    });

    test('SMS認証サービス→credential生成', () {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = PhoneAuthService(auth: mockAuth);
      final credential = service.createCredential(
        verificationId: 'test-vid',
        smsCode: '123456',
      );

      expect(credential, isNotNull);
    });
  });
}
