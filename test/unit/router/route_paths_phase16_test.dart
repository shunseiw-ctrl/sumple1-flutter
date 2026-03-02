import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/router/route_paths.dart';

void main() {
  group('RoutePaths Phase 16', () {
    test('日報・検査・タイムラインのパスが正しい', () {
      expect(RoutePaths.workReportCreate, '/work/:applicationId/report/new');
      expect(RoutePaths.workInspection, '/work/:applicationId/inspection');
      expect(RoutePaths.workTimeline, '/work/:applicationId/timeline');
      expect(RoutePaths.qualifications, '/qualifications');
      expect(RoutePaths.qualificationAdd, '/qualifications/new');
      expect(RoutePaths.statements, '/statements');
      expect(RoutePaths.statementDetail, '/statements/:statementId');
    });

    test('ヘルパーメソッドが正しいパスを生成する', () {
      expect(RoutePaths.workReportCreatePath('app-001'),
          '/work/app-001/report/new');
      expect(RoutePaths.workInspectionPath('app-001'),
          '/work/app-001/inspection');
      expect(RoutePaths.workTimelinePath('app-001'),
          '/work/app-001/timeline');
      expect(RoutePaths.statementDetailPath('stmt-001'),
          '/statements/stmt-001');
    });
  });
}
