import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/early_payment_request_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('EarlyPaymentRequestModel', () {
    test('fromMap で正しく生成される', () {
      final data = TestFixtures.earlyPaymentRequestData();
      final model = EarlyPaymentRequestModel.fromMap('req-001', data);

      expect(model.id, 'req-001');
      expect(model.workerUid, 'worker-001');
      expect(model.statementId, 'stmt-001');
      expect(model.month, '2025-04');
      expect(model.requestedAmount, 150000);
      expect(model.earlyPaymentFee, 15000);
      expect(model.payoutAmount, 135000);
      expect(model.status, 'requested');
    });

    test('手数料計算が正しい', () {
      // 10% 手数料
      expect(EarlyPaymentRequestModel.calculateFee(100000), 10000);
      expect(EarlyPaymentRequestModel.calculatePayout(100000), 90000);

      expect(EarlyPaymentRequestModel.calculateFee(150000), 15000);
      expect(EarlyPaymentRequestModel.calculatePayout(150000), 135000);

      expect(EarlyPaymentRequestModel.feeRate, 0.10);
    });

    test('statusLabel が正しく動作する', () {
      final requested = EarlyPaymentRequestModel.fromMap(
          'r1', TestFixtures.earlyPaymentRequestData(status: 'requested'));
      expect(requested.statusLabel, '申請中');

      final approved = EarlyPaymentRequestModel.fromMap(
          'r2', TestFixtures.earlyPaymentRequestData(status: 'approved'));
      expect(approved.statusLabel, '承認済み');

      final rejected = EarlyPaymentRequestModel.fromMap(
          'r3', TestFixtures.earlyPaymentRequestData(status: 'rejected'));
      expect(rejected.statusLabel, '却下');

      final paid = EarlyPaymentRequestModel.fromMap(
          'r4', TestFixtures.earlyPaymentRequestData(status: 'paid'));
      expect(paid.statusLabel, '支払済み');
    });
  });
}
