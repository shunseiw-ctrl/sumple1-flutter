import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/inspection_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('InspectionCheckItem', () {
    test('fromMap/toMap ラウンドトリップ', () {
      final data = TestFixtures.inspectionCheckItemData(comment: '良好');
      final item = InspectionCheckItem.fromMap(data);

      expect(item.label, '仕上がり品質');
      expect(item.result, 'pass');
      expect(item.comment, '良好');

      final map = item.toMap();
      expect(map['label'], '仕上がり品質');
      expect(map['result'], 'pass');
      expect(map['comment'], '良好');
    });
  });

  group('InspectionModel', () {
    test('fromMap で正しく生成される', () {
      final data = TestFixtures.inspectionData();
      final model = InspectionModel.fromMap('insp-001', data);

      expect(model.id, 'insp-001');
      expect(model.applicationId, 'app-001');
      expect(model.inspectorUid, 'admin-001');
      expect(model.result, 'passed');
      expect(model.items.length, 2);
      expect(model.items.first.label, '仕上がり品質');
    });

    test('toMap で正しく変換される', () {
      final data = TestFixtures.inspectionData(overallComment: '全体的に良好');
      final model = InspectionModel.fromMap('insp-001', data);
      final map = model.toMap();

      expect(map['applicationId'], 'app-001');
      expect(map['result'], 'passed');
      expect(map['overallComment'], '全体的に良好');
      expect((map['items'] as List).length, 2);
    });

    test('isPassed / hasFailed が正しく動作する', () {
      final passed = InspectionModel.fromMap('insp-001',
          TestFixtures.inspectionData(result: 'passed'));
      expect(passed.isPassed, isTrue);
      expect(passed.hasFailed, isFalse);

      final failedData = TestFixtures.inspectionData(
        result: 'failed',
        items: [
          {'label': '仕上がり品質', 'result': 'fail'},
          {'label': '清掃状況', 'result': 'pass'},
        ],
      );
      final failed = InspectionModel.fromMap('insp-002', failedData);
      expect(failed.isPassed, isFalse);
      expect(failed.hasFailed, isTrue);
    });

    test('equality が正しく動作する', () {
      final data = TestFixtures.inspectionData();
      final model1 = InspectionModel.fromMap('insp-001', data);
      final model2 = InspectionModel.fromMap('insp-001', data);
      final model3 = InspectionModel.fromMap('insp-002', data);

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
      expect(model1, isNot(equals(model3)));
    });
  });
}
