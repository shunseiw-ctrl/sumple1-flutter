import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_approval_provider.dart';

void main() {
  group('ApprovalItem', () {
    test('ApprovalType_3種別定義', () {
      expect(ApprovalType.values.length, 3);
      expect(ApprovalType.values, contains(ApprovalType.qualification));
      expect(ApprovalType.values, contains(ApprovalType.earlyPayment));
      expect(ApprovalType.values, contains(ApprovalType.verification));
    });

    test('ApprovalItem_コンストラクタ_全フィールド', () {
      final item = ApprovalItem(
        id: 'test-id',
        workerUid: 'worker-1',
        type: ApprovalType.qualification,
        data: {'name': 'テスト資格'},
        createdAt: DateTime(2024, 1, 1),
        parentPath: 'profiles/worker-1',
      );

      expect(item.id, 'test-id');
      expect(item.workerUid, 'worker-1');
      expect(item.type, ApprovalType.qualification);
      expect(item.data['name'], 'テスト資格');
      expect(item.createdAt, DateTime(2024, 1, 1));
      expect(item.parentPath, 'profiles/worker-1');
    });

    test('ApprovalItem_parentPathなし_nullを許容', () {
      final item = ApprovalItem(
        id: 'test-id',
        workerUid: 'worker-1',
        type: ApprovalType.earlyPayment,
        data: {},
      );

      expect(item.parentPath, isNull);
      expect(item.createdAt, isNull);
    });
  });

  group('ApprovalType', () {
    test('qualification_資格承認', () {
      expect(ApprovalType.qualification.name, 'qualification');
    });

    test('earlyPayment_即金承認', () {
      expect(ApprovalType.earlyPayment.name, 'earlyPayment');
    });

    test('verification_本人確認', () {
      expect(ApprovalType.verification.name, 'verification');
    });
  });
}
