import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/inspection_service.dart';
import 'package:sumple1/data/models/inspection_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late InspectionService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'admin-001'),
    );
    service = InspectionService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('InspectionService', () {
    test('submitInspection が検査ドキュメントを作成する', () async {
      final items = [
        InspectionCheckItem(label: '仕上がり品質', result: 'pass'),
        InspectionCheckItem(label: '清掃状況', result: 'pass'),
      ];

      await service.submitInspection(
        applicationId: 'app-001',
        result: 'passed',
        items: items,
        overallComment: '問題なし',
      );

      final snap = await fakeFirestore
          .collection('applications')
          .doc('app-001')
          .collection('inspections')
          .get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['result'], 'passed');
      expect(data['inspectorUid'], 'admin-001');
      expect((data['items'] as List).length, 2);
    });

    test('watchLatestInspection が最新の検査を返す', () async {
      await fakeFirestore
          .collection('applications')
          .doc('app-001')
          .collection('inspections')
          .add({
        'applicationId': 'app-001',
        'inspectorUid': 'admin-001',
        'result': 'passed',
        'items': [
          {'label': '仕上がり品質', 'result': 'pass'},
        ],
        'photoUrls': <String>[],
        'createdAt': DateTime(2025, 4, 1),
      });

      final inspection =
          await service.watchLatestInspection('app-001').first;
      expect(inspection, isNotNull);
      expect(inspection!.result, 'passed');
    });
  });
}
