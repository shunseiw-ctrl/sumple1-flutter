import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/job_detail_page.dart';

void main() {
  Widget buildTestWidget(Map<String, dynamic> data) {
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
      home: Scaffold(
        body: JobDetailBody(data: data),
      ),
    );
  }

  group('JobDetailBody', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都渋谷区',
        'price': '30000',
        'date': '2026-03-15',
      }));
      await tester.pumpAndSettle();

      expect(find.text('テスト案件'), findsOneWidget);
    });

    testWidgets('displays location', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '千葉県千葉市',
        'price': '25000',
        'date': '2026-04-01',
      }));
      await tester.pumpAndSettle();

      expect(find.text('千葉県千葉市'), findsWidgets);
    });

    testWidgets('displays price with yen symbol', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都',
        'price': '50000',
        'date': '2026-03-20',
      }));
      await tester.pumpAndSettle();

      expect(find.text('¥50000'), findsOneWidget);
    });

    testWidgets('displays date', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都',
        'price': '30000',
        'date': '2026-03-15',
      }));
      await tester.pumpAndSettle();

      expect(find.text('2026-03-15'), findsWidgets);
    });

    testWidgets('shows default description when empty', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都',
        'price': '30000',
        'date': '2026-03-15',
        'description': '',
      }));
      await tester.pumpAndSettle();

      expect(find.textContaining('詳細情報はまだ登録されていません'), findsOneWidget);
    });

    testWidgets('shows custom description when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都',
        'price': '30000',
        'date': '2026-03-15',
        'description': 'カスタム仕事内容です',
      }));
      await tester.pumpAndSettle();

      expect(find.text('カスタム仕事内容です'), findsOneWidget);
    });

    testWidgets('displays default values when data is missing', (tester) async {
      await tester.pumpWidget(buildTestWidget({}));
      await tester.pumpAndSettle();

      expect(find.text('タイトルなし'), findsOneWidget);
      expect(find.text('¥0'), findsOneWidget);
    });
  });

  group('JobDetailBody Hero', () {
    testWidgets('詳細画面にHero widgetが存在（jobId + imageUrl指定時）', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppColorsExtension.light]),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: JobDetailBody(
            data: const {
              'title': 'テスト',
              'location': '東京',
              'price': '10000',
              'date': '2026-04-01',
              'imageUrl': 'https://example.com/test.jpg',
            },
            jobId: 'abc123',
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('Heroタグフォーマットがjob_cardと一致', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppColorsExtension.light]),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: JobDetailBody(
            data: const {
              'title': 'テスト',
              'location': '東京',
              'price': '10000',
              'date': '2026-04-01',
              'imageUrl': 'https://example.com/test.jpg',
            },
            jobId: 'abc123',
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'hero-job-image-abc123');
    });

    testWidgets('jobId未指定時はHeroなし', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppColorsExtension.light]),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: JobDetailBody(
            data: const {
              'title': 'テスト',
              'location': '東京',
              'price': '10000',
              'date': '2026-04-01',
              'imageUrl': 'https://example.com/test.jpg',
            },
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(Hero), findsNothing);
    });
  });
}
