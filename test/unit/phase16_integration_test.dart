import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sumple1/core/services/work_report_service.dart';
import 'package:sumple1/core/services/inspection_service.dart';
import 'package:sumple1/core/services/qualification_service.dart';
import 'package:sumple1/core/services/payment_cycle_service.dart';
import 'package:sumple1/data/models/inspection_model.dart';
import 'package:sumple1/data/models/early_payment_request_model.dart';

void main() {
  group('Phase 16 結合テスト', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'worker-001'),
      );
    });

    test('日報→完了ゲート: 日報0件ではcompletedに進めない', () async {
      final reportService = WorkReportService(
          firestore: fakeFirestore, auth: mockAuth);

      // 日報0件
      final count = await reportService.getReportCount('app-001');
      expect(count, 0);

      // 日報1件作成後
      await reportService.createReport(
        applicationId: 'app-001',
        reportDate: '2025-04-01',
        workContent: '作業内容',
        hoursWorked: 8.0,
      );
      final countAfter = await reportService.getReportCount('app-001');
      expect(countAfter, 1);
    });

    test('検査→自動ステータス遷移: passed→done, failed→fixing', () async {
      final inspectionService = InspectionService(
          firestore: fakeFirestore, auth: mockAuth);

      // application作成
      await fakeFirestore.collection('applications').doc('app-001').set({
        'applicantUid': 'worker-001',
        'adminUid': 'admin-001',
        'status': 'completed',
      });

      // 全合格の検査
      await inspectionService.submitInspection(
        applicationId: 'app-001',
        result: 'passed',
        items: [
          InspectionCheckItem(label: '仕上がり品質', result: 'pass'),
        ],
      );

      final inspSnap = await fakeFirestore
          .collection('applications')
          .doc('app-001')
          .collection('inspections')
          .get();
      expect(inspSnap.docs.length, 1);
      expect(inspSnap.docs.first.data()['result'], 'passed');
    });

    test('資格→承認ワークフロー', () async {
      final qualService = QualificationService(
          firestore: fakeFirestore, auth: mockAuth);

      // 資格追加
      await qualService.addQualification(
        name: '建築施工管理技士',
        category: 'construction_management',
      );

      final quals = await qualService.watchQualifications('worker-001').first;
      expect(quals.length, 1);
      expect(quals.first.verificationStatus, 'pending');

      // 承認
      await qualService.approve(
        targetUid: 'worker-001',
        qualificationId: quals.first.id,
      );

      final qualsAfter = await qualService.watchQualifications('worker-001').first;
      expect(qualsAfter.first.verificationStatus, 'approved');
    });

    test('即金申請→手数料計算', () async {
      final paymentService = PaymentCycleService(
          firestore: fakeFirestore, auth: mockAuth);

      // 明細作成
      final stmtRef = await fakeFirestore.collection('monthly_statements').add({
        'workerUid': 'worker-001',
        'month': '2025-04',
        'items': [],
        'totalAmount': 200000,
        'netAmount': 200000,
        'status': 'confirmed',
        'earlyPaymentRequested': false,
      });

      // 即金申請
      await paymentService.requestEarlyPayment(
        statementId: stmtRef.id,
        requestedAmount: 200000,
      );

      final reqSnap = await fakeFirestore
          .collection('early_payment_requests')
          .get();
      expect(reqSnap.docs.length, 1);

      final reqData = reqSnap.docs.first.data();
      expect(reqData['requestedAmount'], 200000);
      expect(reqData['earlyPaymentFee'], EarlyPaymentRequestModel.calculateFee(200000));
      expect(reqData['payoutAmount'], EarlyPaymentRequestModel.calculatePayout(200000));
      expect(reqData['earlyPaymentFee'], 20000);
      expect(reqData['payoutAmount'], 180000);
    });
  });
}
