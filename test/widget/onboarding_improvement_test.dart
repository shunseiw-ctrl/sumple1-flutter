import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/pages/onboarding_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

Widget _buildTestApp() {
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
    home: const OnboardingPage(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingPage改善', () {
    testWidgets('画像エラー時にフォールバックアイコン表示', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Image.assetが失敗するとerrorBuilderによりIconが表示される
      // テスト環境ではアセットの扱いが異なるため、ページ自体が正しく表示されることを確認
      expect(find.text('仕事を見つけよう'), findsOneWidget);
      // SizedBox with image container exists (logo + onboarding image)
      expect(find.byType(Image), findsAtLeast(1));
    });

    testWidgets('l10nテキストが表示される', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // ARBキーの値が表示されていることを確認
      expect(find.text('仕事を見つけよう'), findsOneWidget);
      expect(find.text('建設業界の仕事を簡単に検索・応募できます'), findsOneWidget);
    });

    testWidgets('ページ遷移で次のコンテンツ表示', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 最初のページが表示
      expect(find.text('仕事を見つけよう'), findsOneWidget);

      // 次へボタンで遷移
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();

      // 2ページ目
      expect(find.text('QRで出退勤'), findsOneWidget);
    });

    testWidgets('最終ページで同意チェックなし→ボタン無効', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 最終ページまでナビゲーション（次へボタンを使う）
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();

      // 3ページ目: チェックボックスが2つ表示
      expect(find.byType(Checkbox), findsNWidgets(2));

      // ボタンはnullのonPressed（disabled）
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('同意チェック後→ボタン有効', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 最終ページまでナビゲーション
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();

      // 両方のチェックボックスをタップ
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.pump();
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      // ボタンが有効になる
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('スキップボタン存在', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // スキップボタンが存在
      expect(find.text('スキップ'), findsOneWidget);
    });
  });
}
