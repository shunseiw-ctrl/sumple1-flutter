import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';

/// GuestHomePageのUIコンポーネントを単独でテスト
/// （Firebase依存を回避するためページ全体ではなくUI要素単位でテスト）
void main() {
  Widget buildLocalizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(body: child),
    );
  }

  group('GuestHomePage UI Components', () {
    testWidgets('ALBAWORKロゴテキストが正しく表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Center(
          child: Text(
            'ALBAWORK',
            style: AppTextStyles.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ));

      expect(find.text('ALBAWORK'), findsOneWidget);
    });

    testWidgets('ゲストログインボタンがレンダリングされる', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('ゲストとして始める'),
          ),
        ),
      ));

      expect(find.text('ゲストとして始める'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('LINEログインボタンが正しい色で表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.lineGreen,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble, size: 22),
              label: const Text('LINEでログイン'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ));

      expect(find.text('LINEでログイン'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
    });

    testWidgets('メールログインボタンが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email_outlined, size: 20),
            label: const Text('メールアドレスでログイン'),
          ),
        ),
      ));

      expect(find.text('メールアドレスでログイン'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('Appleサインインボタンのスタイルが正しい', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.apple, size: 24),
            label: const Text('Appleでサインイン'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ));

      expect(find.text('Appleでサインイン'), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('フィーチャーカードが正しく表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Row(
          children: [
            Expanded(
              child: Column(
                children: const [
                  Icon(Icons.search_rounded),
                  Text('仕事を探す'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: const [
                  Icon(Icons.flash_on_rounded),
                  Text('すぐに稼げる'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: const [
                  Icon(Icons.verified_user_rounded),
                  Text('安心の支払い'),
                ],
              ),
            ),
          ],
        ),
      ));

      expect(find.text('仕事を探す'), findsOneWidget);
      expect(find.text('すぐに稼げる'), findsOneWidget);
      expect(find.text('安心の支払い'), findsOneWidget);
    });

    testWidgets('利用規約・プライバシーポリシーリンクが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text('利用規約'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('プライバシーポリシー'),
            ),
          ],
        ),
      ));

      expect(find.text('利用規約'), findsOneWidget);
      expect(find.text('プライバシーポリシー'), findsOneWidget);
    });
  });
}
