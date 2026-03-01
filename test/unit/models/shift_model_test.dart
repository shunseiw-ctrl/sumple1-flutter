import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/shift_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ShiftModel', () {
    group('fromMap', () {
      test('完全なデータで正しく生成される', () {
        final data = TestFixtures.shiftData();
        final model = ShiftModel.fromMap('shift-001', data);

        expect(model.id, 'shift-001');
        expect(model.date, '2025-04-01');
        expect(model.qrCode, 'shift-abc123');
        expect(model.createdBy, 'admin-001');
        expect(model.createdAt, isNotNull);
      });

      test('必須フィールドが欠落した場合は空文字列', () {
        final model = ShiftModel.fromMap('shift-002', {});

        expect(model.date, '');
        expect(model.qrCode, '');
        expect(model.createdBy, '');
        expect(model.createdAt, isNull);
      });

      test('DateTimeフィールドが正しく変換される', () {
        final now = DateTime(2025, 3, 15);
        final model = ShiftModel.fromMap('shift-003', {
          ...TestFixtures.shiftData(),
          'createdAt': now,
        });
        expect(model.createdAt, now);
      });
    });

    group('equality', () {
      test('同一フィールドのオブジェクトは等しい', () {
        final now = DateTime(2025, 3, 15);
        final model1 = ShiftModel(
          id: 'shift-001',
          date: '2025-04-01',
          qrCode: 'shift-abc123',
          createdBy: 'admin-001',
          createdAt: now,
        );
        final model2 = ShiftModel(
          id: 'shift-001',
          date: '2025-04-01',
          qrCode: 'shift-abc123',
          createdBy: 'admin-001',
          createdAt: now,
        );

        expect(model1, equals(model2));
        expect(model1.hashCode, equals(model2.hashCode));
      });

      test('異なるフィールドのオブジェクトは等しくない', () {
        final model1 = ShiftModel.fromMap('shift-001', TestFixtures.shiftData());
        final model2 = ShiftModel.fromMap('shift-002', TestFixtures.shiftData(
          date: '2025-05-01',
          qrCode: 'shift-xyz789',
        ));

        expect(model1, isNot(equals(model2)));
      });
    });

    group('toCreateMap', () {
      test('必要なフィールドが含まれる', () {
        final model = ShiftModel(
          id: 'shift-001',
          date: '2025-04-01',
          qrCode: 'shift-abc123',
          createdBy: 'admin-001',
        );
        final map = model.toCreateMap();

        expect(map['date'], '2025-04-01');
        expect(map['qrCode'], 'shift-abc123');
        expect(map['createdBy'], 'admin-001');
        expect(map.containsKey('createdAt'), isTrue);
      });

      test('idは含まれない', () {
        final model = ShiftModel(
          id: 'shift-001',
          date: '2025-04-01',
          qrCode: 'shift-abc123',
          createdBy: 'admin-001',
        );
        final map = model.toCreateMap();
        expect(map.containsKey('id'), isFalse);
      });
    });
  });
}
