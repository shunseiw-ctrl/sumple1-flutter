import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_inspections_provider.dart';

void main() {
  group('InspectionItem', () {
    test('コンストラクタ_必須フィールド', () {
      final item = InspectionItem(
        id: 'insp-1',
        applicationId: 'app-1',
        inspectorUid: 'admin-1',
        result: 'passed',
        totalItems: 6,
        passedItems: 6,
      );

      expect(item.id, 'insp-1');
      expect(item.result, 'passed');
      expect(item.totalItems, 6);
      expect(item.passedItems, 6);
      expect(item.workerName, '');
    });

    test('copyWith_workerNameを更新', () {
      final item = InspectionItem(
        id: 'i1',
        applicationId: 'a1',
        inspectorUid: 'admin-1',
        result: 'failed',
        totalItems: 6,
        passedItems: 3,
      );

      final updated = item.copyWith(workerName: '佐藤花子');
      expect(updated.workerName, '佐藤花子');
      expect(updated.result, 'failed');
    });

    test('partial結果_一部合格', () {
      final item = InspectionItem(
        id: 'i2',
        applicationId: 'a2',
        inspectorUid: 'admin-1',
        result: 'partial',
        totalItems: 6,
        passedItems: 4,
        overallComment: '一部不備あり',
      );

      expect(item.result, 'partial');
      expect(item.overallComment, '一部不備あり');
    });

    test('createdAt_nullを許容', () {
      final item = InspectionItem(
        id: 'i3',
        applicationId: 'a3',
        inspectorUid: 'admin-1',
        result: 'passed',
        totalItems: 6,
        passedItems: 6,
      );

      expect(item.createdAt, isNull);
    });
  });
}
