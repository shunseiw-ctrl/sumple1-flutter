import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/map_search_page.dart';

void main() {
  group('MapSearchPage ナビゲーション', () {
    testWidgets('空jobリスト→「案件がありません」メッセージ', (tester) async {
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
        home: const MapSearchPage(initialJobs: []),
      ));

      expect(find.text('地図に表示できる案件がありません'), findsOneWidget);
    });

    testWidgets('lat/lngなしのjobのみ→「案件がありません」メッセージ', (tester) async {
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
        home: MapSearchPage(initialJobs: [
          {'data': <String, dynamic>{'title': 'テスト'}, 'docId': 'job-001'},
        ]),
      ));

      expect(find.text('地図に表示できる案件がありません'), findsOneWidget);
    });

    testWidgets('nullジョブリスト→「案件がありません」メッセージ', (tester) async {
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
        home: const MapSearchPage(initialJobs: null),
      ));

      expect(find.text('地図に表示できる案件がありません'), findsOneWidget);
    });
  });
}
