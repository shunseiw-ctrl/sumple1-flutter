import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/services/qualification_service.dart';
import 'package:sumple1/pages/admin/admin_qualifications_page.dart';

class MockQualificationService extends Mock implements QualificationService {}

void main() {
  group('AdminQualificationsPage（実ページ）', () {
    testWidgets('承認待ちなし→空状態表示', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockService = MockQualificationService();

      // profiles exists but no pending qualifications
      await fakeFirestore.collection('profiles').doc('user1').set({
        'displayName': 'テストユーザー',
      });

      await tester.pumpWidget(MaterialApp(
        home: AdminQualificationsPage(
          qualificationService: mockService,
          firestore: fakeFirestore,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('資格承認'), findsOneWidget);
      expect(find.text('承認待ちの資格はありません'), findsOneWidget);
    });

    testWidgets('承認待ちリスト表示', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockService = MockQualificationService();

      // Profile with pending qualification
      await fakeFirestore.collection('profiles').doc('worker1').set({
        'displayName': '田中太郎',
      });
      await fakeFirestore
          .collection('profiles')
          .doc('worker1')
          .collection('qualifications_v2')
          .doc('qual1')
          .set({
        'name': '内装仕上げ施工技能士',
        'category': 'interior',
        'verificationStatus': 'pending',
        'certPhotoUrl': '',
      });

      await tester.pumpWidget(MaterialApp(
        home: AdminQualificationsPage(
          qualificationService: mockService,
          firestore: fakeFirestore,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('田中太郎'), findsOneWidget);
      expect(find.text('内装仕上げ施工技能士'), findsOneWidget);
      expect(find.text('承認待ち'), findsOneWidget);
    });

    testWidgets('承認・却下ボタン表示', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockService = MockQualificationService();

      await fakeFirestore.collection('profiles').doc('worker2').set({
        'displayName': '佐藤花子',
      });
      await fakeFirestore
          .collection('profiles')
          .doc('worker2')
          .collection('qualifications_v2')
          .doc('qual2')
          .set({
        'name': '足場組立作業主任者',
        'category': 'scaffold',
        'verificationStatus': 'pending',
        'certPhotoUrl': '',
      });

      await tester.pumpWidget(MaterialApp(
        home: AdminQualificationsPage(
          qualificationService: mockService,
          firestore: fakeFirestore,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('承認'), findsOneWidget);
      expect(find.text('却下'), findsOneWidget);
    });
  });
}
