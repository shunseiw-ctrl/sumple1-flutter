import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/phone_auth_page.dart';
import 'package:sumple1/core/services/phone_auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockPhoneAuthService extends Mock implements PhoneAuthService {}

Widget _buildTestApp({PhoneAuthService? phoneAuthService}) {
  return MaterialApp(
    theme: ThemeData(extensions: const [AppColorsExtension.light]),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ja')],
    locale: const Locale('ja'),
    home: PhoneAuthPage(phoneAuthService: phoneAuthService),
  );
}

void main() {
  group('PhoneAuthPage（実ページ）', () {
    late MockPhoneAuthService mockService;

    setUp(() {
      mockService = MockPhoneAuthService();
    });

    testWidgets('電話番号入力フィールド表示', (tester) async {
      await tester.pumpWidget(_buildTestApp(phoneAuthService: mockService));
      await tester.pumpAndSettle();

      // 電話番号入力フィールド
      expect(find.byType(TextField), findsOneWidget);
      // +81バッジ
      expect(find.text('+81'), findsOneWidget);
      // 送信ボタン
      expect(find.text('認証コードを送信'), findsOneWidget);
    });

    testWidgets('バリデーション（短い番号でエラー）', (tester) async {
      await tester.pumpWidget(_buildTestApp(phoneAuthService: mockService));
      await tester.pumpAndSettle();

      // 短い番号を入力
      await tester.enterText(find.byType(TextField), '090');
      await tester.pumpAndSettle();

      // 送信ボタンをタップ
      await tester.tap(find.text('認証コードを送信'));
      await tester.pumpAndSettle();

      // エラーメッセージ（SnackBar）
      expect(find.textContaining('有効な電話番号'), findsOneWidget);
    });

    testWidgets('電話番号フィールドにヒントテキスト', (tester) async {
      await tester.pumpWidget(_buildTestApp(phoneAuthService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('090-1234-5678'), findsOneWidget);
    });
  });
}
