import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/presentation/widgets/load_more_button.dart';

void main() {
  group('LoadMoreButton', () {
    testWidgets('hasMore=true→ボタン表示', (tester) async {
      bool pressed = false;

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
          body: LoadMoreButton(
            hasMore: true,
            isLoading: false,
            onPressed: () => pressed = true,
          ),
        ),
      ));

      expect(find.text('もっと表示'), findsOneWidget);
      await tester.tap(find.text('もっと表示'));
      expect(pressed, true);
    });

    testWidgets('isLoading=true→スピナー表示', (tester) async {
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
          body: LoadMoreButton(
            hasMore: true,
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('もっと表示'), findsNothing);
    });

    testWidgets('hasMore=false→非表示', (tester) async {
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
          body: LoadMoreButton(
            hasMore: false,
            isLoading: false,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('もっと表示'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
