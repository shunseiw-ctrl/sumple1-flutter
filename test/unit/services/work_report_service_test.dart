import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/work_report_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late WorkReportService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'worker-001'),
    );
    service = WorkReportService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('WorkReportService', () {
    test('createReport が日報ドキュメントを作成する', () async {
      await service.createReport(
        applicationId: 'app-001',
        reportDate: '2025-04-01',
        workContent: '内装工事を実施',
        hoursWorked: 8.0,
      );

      final snap = await fakeFirestore
          .collection('applications')
          .doc('app-001')
          .collection('work_reports')
          .get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['workerUid'], 'worker-001');
      expect(data['workContent'], '内装工事を実施');
      expect(data['hoursWorked'], 8.0);
    });

    test('watchReports が日報一覧をストリームで返す', () async {
      await fakeFirestore
          .collection('applications')
          .doc('app-001')
          .collection('work_reports')
          .add({
        'applicationId': 'app-001',
        'workerUid': 'worker-001',
        'reportDate': '2025-04-01',
        'workContent': '作業内容',
        'hoursWorked': 8.0,
        'photoUrls': <String>[],
      });

      final reports = await service.watchReports('app-001').first;
      expect(reports.length, 1);
      expect(reports.first.reportDate, '2025-04-01');
    });

    test('getReportCount が件数を返す', () async {
      await fakeFirestore
          .collection('applications')
          .doc('app-001')
          .collection('work_reports')
          .add({
        'applicationId': 'app-001',
        'workerUid': 'worker-001',
        'reportDate': '2025-04-01',
        'workContent': '作業内容',
        'hoursWorked': 8.0,
        'photoUrls': <String>[],
      });

      final count = await service.getReportCount('app-001');
      expect(count, 1);

      final emptyCount = await service.getReportCount('app-999');
      expect(emptyCount, 0);
    });
  });
}
