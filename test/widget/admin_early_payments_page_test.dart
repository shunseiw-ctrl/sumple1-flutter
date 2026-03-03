import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/payment_cycle_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/admin/admin_early_payments_page.dart';

class MockPaymentCycleService extends Mock implements PaymentCycleService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('AdminEarlyPaymentsPage（実ページ）', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockPaymentCycleService mockPaymentService;
    late MockNotificationService mockNotificationService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockPaymentService = MockPaymentCycleService();
      mockNotificationService = MockNotificationService();
    });

    Widget buildPage() {
      return MaterialApp(
        theme: ThemeData(extensions: const [AppColorsExtension.light]),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: AdminEarlyPaymentsPage(
          paymentCycleService: mockPaymentService,
          firestore: fakeFirestore,
          notificationService: mockNotificationService,
        ),
      );
    }

    testWidgets('申請0件→空状態表示', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('即金申請一覧'), findsOneWidget);
      expect(find.text('承認待ちの即金申請はありません'), findsOneWidget);
    });

    testWidgets('申請リスト表示・金額フォーマット確認', (tester) async {
      // Worker profile
      await fakeFirestore.collection('profiles').doc('worker1').set({
        'displayName': '田中太郎',
      });

      // Early payment request
      await fakeFirestore
          .collection('early_payment_requests')
          .doc('req1')
          .set({
        'workerUid': 'worker1',
        'month': '2025-04',
        'status': 'requested',
        'requestedAmount': 150000,
        'earlyPaymentFee': 15000,
        'payoutAmount': 135000,
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // Worker name (via FutureBuilder)
      expect(find.text('田中太郎'), findsOneWidget);
      // Amount formatting
      expect(find.text('150,000円'), findsOneWidget);
      // Fee
      expect(find.text('-15,000円'), findsOneWidget);
      // Payout
      expect(find.text('135,000円'), findsOneWidget);
      // Month
      expect(find.text('2025-04'), findsOneWidget);
    });

    testWidgets('承認・却下ボタン表示', (tester) async {
      await fakeFirestore.collection('profiles').doc('worker2').set({
        'displayName': '佐藤花子',
      });

      await fakeFirestore
          .collection('early_payment_requests')
          .doc('req2')
          .set({
        'workerUid': 'worker2',
        'month': '2025-05',
        'status': 'requested',
        'requestedAmount': 80000,
        'earlyPaymentFee': 8000,
        'payoutAmount': 72000,
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('承認'), findsOneWidget);
      expect(find.text('却下'), findsOneWidget);
    });
  });
}
