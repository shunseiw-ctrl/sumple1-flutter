import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/payment_cycle_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late PaymentCycleService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'worker-001'),
    );
    service = PaymentCycleService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('PaymentCycleService', () {
    test('requestEarlyPayment が即金申請を作成する', () async {
      // まず明細を作成
      final stmtRef =
          await fakeFirestore.collection('monthly_statements').add({
        'workerUid': 'worker-001',
        'month': '2025-04',
        'items': [],
        'totalAmount': 150000,
        'netAmount': 150000,
        'status': 'confirmed',
        'earlyPaymentRequested': false,
      });

      await service.requestEarlyPayment(
        statementId: stmtRef.id,
        requestedAmount: 150000,
      );

      // 即金申請が作成されたか
      final reqSnap =
          await fakeFirestore.collection('early_payment_requests').get();
      expect(reqSnap.docs.length, 1);
      final reqData = reqSnap.docs.first.data();
      expect(reqData['workerUid'], 'worker-001');
      expect(reqData['requestedAmount'], 150000);
      expect(reqData['earlyPaymentFee'], 15000);
      expect(reqData['payoutAmount'], 135000);
      expect(reqData['status'], 'requested');

      // 明細にフラグが立ったか
      final stmtDoc = await fakeFirestore
          .collection('monthly_statements')
          .doc(stmtRef.id)
          .get();
      expect(stmtDoc.data()!['earlyPaymentRequested'], true);
    });

    test('approveEarlyPayment が申請を承認する', () async {
      final reqRef =
          await fakeFirestore.collection('early_payment_requests').add({
        'workerUid': 'worker-001',
        'statementId': 'stmt-001',
        'month': '2025-04',
        'requestedAmount': 150000,
        'earlyPaymentFee': 15000,
        'payoutAmount': 135000,
        'status': 'requested',
      });

      await service.approveEarlyPayment(reqRef.id);

      final doc = await fakeFirestore
          .collection('early_payment_requests')
          .doc(reqRef.id)
          .get();
      expect(doc.data()!['status'], 'approved');
      expect(doc.data()!['reviewedBy'], 'worker-001');
    });
  });
}
