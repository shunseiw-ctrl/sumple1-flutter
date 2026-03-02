import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/monthly_statement_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('MonthlyStatementModel', () {
    test('fromMap で正しく生成される', () {
      final data = TestFixtures.monthlyStatementData();
      final model = MonthlyStatementModel.fromMap('stmt-001', data);

      expect(model.id, 'stmt-001');
      expect(model.workerUid, 'worker-001');
      expect(model.month, '2025-04');
      expect(model.totalAmount, 150000);
      expect(model.netAmount, 150000);
      expect(model.status, 'draft');
      expect(model.items.length, 1);
      expect(model.items.first.jobTitle, '内装工事');
      expect(model.earlyPaymentRequested, isFalse);
    });

    test('toMap / statusLabel が正しく動作する', () {
      final draft = MonthlyStatementModel.fromMap(
          'stmt-001', TestFixtures.monthlyStatementData(status: 'draft'));
      expect(draft.statusLabel, '集計中');

      final confirmed = MonthlyStatementModel.fromMap(
          'stmt-002', TestFixtures.monthlyStatementData(status: 'confirmed'));
      expect(confirmed.statusLabel, '確定済み');

      final paid = MonthlyStatementModel.fromMap(
          'stmt-003', TestFixtures.monthlyStatementData(status: 'paid'));
      expect(paid.statusLabel, '支払済み');

      final map = draft.toMap();
      expect(map['workerUid'], 'worker-001');
      expect(map['month'], '2025-04');
      expect(map['totalAmount'], 150000);
    });

    test('equality が正しく動作する', () {
      final data = TestFixtures.monthlyStatementData();
      final model1 = MonthlyStatementModel.fromMap('stmt-001', data);
      final model2 = MonthlyStatementModel.fromMap('stmt-001', data);
      final model3 = MonthlyStatementModel.fromMap('stmt-002', data);

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
      expect(model1, isNot(equals(model3)));
    });
  });

  group('StatementLineItem', () {
    test('fromMap / toMap ラウンドトリップ', () {
      final data = {
        'applicationId': 'app-001',
        'jobTitle': '内装工事',
        'completedDate': '2025-04-15',
        'amount': 150000,
      };
      final item = StatementLineItem.fromMap(data);

      expect(item.applicationId, 'app-001');
      expect(item.jobTitle, '内装工事');
      expect(item.completedDate, '2025-04-15');
      expect(item.amount, 150000);

      final map = item.toMap();
      expect(map, data);
    });
  });
}
