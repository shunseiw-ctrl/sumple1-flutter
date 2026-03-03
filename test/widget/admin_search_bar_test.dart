import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/presentation/widgets/admin_search_bar.dart';

void main() {
  group('AdminSearchBar', () {
    testWidgets('テキスト入力→onChanged発火（debounce後）', (tester) async {
      String? lastValue;

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
          body: AdminSearchBar(
            onChanged: (v) => lastValue = v,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'test');
      // debounce前は発火していない可能性
      await tester.pump(const Duration(milliseconds: 350));

      expect(lastValue, 'test');
    });

    testWidgets('クリアボタン動作', (tester) async {
      String? lastValue;

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
          body: AdminSearchBar(
            onChanged: (v) => lastValue = v,
          ),
        ),
      ));

      // テキストを入力
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      // クリアボタンをタップ
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();

      expect(lastValue, '');
    });
  });
}
