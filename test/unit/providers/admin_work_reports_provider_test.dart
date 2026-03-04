import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_work_reports_provider.dart';

void main() {
  group('WorkReportItem', () {
    test('コンストラクタ_必須フィールド', () {
      final item = WorkReportItem(
        id: 'report-1',
        applicationId: 'app-1',
        workerUid: 'worker-1',
        reportDate: '2024-01-15',
        workContent: 'テスト作業内容',
        hoursWorked: 8.0,
      );

      expect(item.id, 'report-1');
      expect(item.applicationId, 'app-1');
      expect(item.workerUid, 'worker-1');
      expect(item.reportDate, '2024-01-15');
      expect(item.workContent, 'テスト作業内容');
      expect(item.hoursWorked, 8.0);
      expect(item.photoUrls, isEmpty);
      expect(item.workerName, '');
    });

    test('copyWith_workerNameを更新', () {
      final item = WorkReportItem(
        id: 'r1',
        applicationId: 'a1',
        workerUid: 'w1',
        reportDate: '2024-01-01',
        workContent: '内容',
        hoursWorked: 5.0,
      );

      final updated = item.copyWith(workerName: '田中太郎');
      expect(updated.workerName, '田中太郎');
      expect(updated.id, 'r1');
    });

    test('copyWith_jobTitleを更新', () {
      final item = WorkReportItem(
        id: 'r1',
        applicationId: 'a1',
        workerUid: 'w1',
        reportDate: '2024-01-01',
        workContent: '内容',
        hoursWorked: 3.5,
      );

      final updated = item.copyWith(jobTitle: '内装工事A');
      expect(updated.jobTitle, '内装工事A');
    });

    test('photoUrls_リスト保持', () {
      final item = WorkReportItem(
        id: 'r1',
        applicationId: 'a1',
        workerUid: 'w1',
        reportDate: '2024-01-01',
        workContent: '内容',
        hoursWorked: 4.0,
        photoUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      );

      expect(item.photoUrls.length, 2);
    });
  });
}
