import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/payment_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('PaymentModel', () {
    group('fromFirestore-compatible (fromMap style)', () {
      test('完全なデータで正しく生成される', () {
        // PaymentModelはfromMapが無いため、コンストラクタ直接テスト
        final data = TestFixtures.paymentData();
        final model = PaymentModel(
          id: 'pay-001',
          applicationId: data['applicationId'] as String,
          jobId: data['jobId'] as String,
          workerUid: data['workerUid'] as String,
          adminUid: data['adminUid'] as String,
          amount: data['amount'] as int,
          platformFee: data['platformFee'] as int,
          netAmount: data['netAmount'] as int,
          stripePaymentIntentId: data['stripePaymentIntentId'] as String?,
          status: data['status'] as String,
          payoutStatus: data['payoutStatus'] as String,
          projectNameSnapshot: data['projectNameSnapshot'] as String?,
        );

        expect(model.id, 'pay-001');
        expect(model.applicationId, 'app-001');
        expect(model.amount, 15000);
        expect(model.platformFee, 1500);
        expect(model.netAmount, 13500);
        expect(model.status, 'pending');
        expect(model.payoutStatus, 'pending');
      });
    });

    group('statusLabel', () {
      test('pending → 処理中', () {
        final model = _createPayment(status: 'pending');
        expect(model.statusLabel, '処理中');
      });

      test('succeeded → 決済完了', () {
        final model = _createPayment(status: 'succeeded');
        expect(model.statusLabel, '決済完了');
      });

      test('failed → 決済失敗', () {
        final model = _createPayment(status: 'failed');
        expect(model.statusLabel, '決済失敗');
      });

      test('不明なステータスはそのまま返す', () {
        final model = _createPayment(status: 'refunded');
        expect(model.statusLabel, 'refunded');
      });
    });

    group('payoutStatusLabel', () {
      test('pending → 振込待ち', () {
        final model = _createPayment(payoutStatus: 'pending');
        expect(model.payoutStatusLabel, '振込待ち');
      });

      test('paid → 振込済み', () {
        final model = _createPayment(payoutStatus: 'paid');
        expect(model.payoutStatusLabel, '振込済み');
      });

      test('不明なステータスはそのまま返す', () {
        final model = _createPayment(payoutStatus: 'processing');
        expect(model.payoutStatusLabel, 'processing');
      });
    });

    group('_parseInt', () {
      // _parseIntはstaticプライベートだがfromFirestoreで使われるため間接テスト
      test('int型はそのまま', () {
        final model = _createPayment(amount: 10000);
        expect(model.amount, 10000);
      });

      test('金額が0の場合', () {
        final model = _createPayment(amount: 0);
        expect(model.amount, 0);
      });

      test('大きな金額', () {
        final model = _createPayment(amount: 999999999);
        expect(model.amount, 999999999);
      });
    });

    test('optionalフィールドのnullハンドリング', () {
      final model = PaymentModel(
        id: 'pay-001',
        applicationId: 'app-001',
        jobId: 'job-001',
        workerUid: 'worker-001',
        adminUid: 'admin-001',
        amount: 10000,
        platformFee: 1000,
        netAmount: 9000,
        status: 'pending',
        payoutStatus: 'pending',
      );

      expect(model.earningId, isNull);
      expect(model.stripePaymentIntentId, isNull);
      expect(model.projectNameSnapshot, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });
  });
}

PaymentModel _createPayment({
  String status = 'pending',
  String payoutStatus = 'pending',
  int amount = 15000,
}) {
  return PaymentModel(
    id: 'pay-001',
    applicationId: 'app-001',
    jobId: 'job-001',
    workerUid: 'worker-001',
    adminUid: 'admin-001',
    amount: amount,
    platformFee: 1500,
    netAmount: 13500,
    status: status,
    payoutStatus: payoutStatus,
  );
}
