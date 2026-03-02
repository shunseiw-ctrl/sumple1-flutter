import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/work_report_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('WorkReportModel', () {
    test('fromMap で正しく生成される', () {
      final data = TestFixtures.workReportData();
      final model = WorkReportModel.fromMap('report-001', data);

      expect(model.id, 'report-001');
      expect(model.applicationId, 'app-001');
      expect(model.workerUid, 'worker-001');
      expect(model.reportDate, '2025-04-01');
      expect(model.workContent, '内装工事の作業を行いました');
      expect(model.hoursWorked, 8.0);
      expect(model.photoUrls, isEmpty);
    });

    test('toMap で正しく変換される', () {
      final data = TestFixtures.workReportData(
        notes: 'テスト備考',
        photoUrls: ['https://example.com/photo1.jpg'],
      );
      final model = WorkReportModel.fromMap('report-001', data);
      final map = model.toMap();

      expect(map['applicationId'], 'app-001');
      expect(map['workerUid'], 'worker-001');
      expect(map['reportDate'], '2025-04-01');
      expect(map['workContent'], '内装工事の作業を行いました');
      expect(map['hoursWorked'], 8.0);
      expect(map['photoUrls'], ['https://example.com/photo1.jpg']);
      expect(map['notes'], 'テスト備考');
    });

    test('copyWith で正しくコピーされる', () {
      final data = TestFixtures.workReportData();
      final model = WorkReportModel.fromMap('report-001', data);
      final copied = model.copyWith(hoursWorked: 6.5, notes: '新しい備考');

      expect(copied.id, 'report-001');
      expect(copied.hoursWorked, 6.5);
      expect(copied.notes, '新しい備考');
      expect(copied.workContent, model.workContent);
    });

    test('equality が正しく動作する', () {
      final data = TestFixtures.workReportData();
      final model1 = WorkReportModel.fromMap('report-001', data);
      final model2 = WorkReportModel.fromMap('report-001', data);
      final model3 = WorkReportModel.fromMap('report-002', data);

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
      expect(model1, isNot(equals(model3)));
    });
  });
}
