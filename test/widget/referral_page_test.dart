import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/referral_page.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  const testUid = 'referral-test-user';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    final mockUser = MockUser(uid: testUid, isAnonymous: false);
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  });

  Widget buildTestWidget() {
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
      home: ReferralPage(
        firestore: fakeFirestore,
        firebaseAuth: mockAuth,
      ),
    );
  }

  group('ReferralPage', () {
    testWidgets('紹介コード表示エリアが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // タイトルとコード表示エリアが存在すること
      expect(find.text('友達を招待'), findsOneWidget);
      expect(find.text('あなたの紹介コード'), findsOneWidget);
    });

    testWidgets('コード入力フィールドが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('紹介コードを入力'), findsAtLeastNWidgets(1));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('適用する'), findsOneWidget);
    });

    testWidgets('シェアボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('シェア'), findsOneWidget);
      expect(find.text('コピー'), findsOneWidget);
    });

    testWidgets('紹介実績エリアが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('紹介実績'), findsOneWidget);
      expect(find.text('0 人'), findsOneWidget);
      expect(find.text('友達を招待して特典を受け取ろう'), findsOneWidget);
    });
  });
}
