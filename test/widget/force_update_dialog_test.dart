import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/presentation/widgets/force_update_dialog.dart';

void main() {
  group('ForceUpdateDialog', () {
    testWidgets('isForced=trueでは「あとで」ボタン非表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColorsExtension.light]),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: const Scaffold(
            body: ForceUpdateDialog(
              isForced: true,
              storeUrl: 'https://example.com',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('あとで'), findsNothing);
      expect(find.text('アップデート'), findsOneWidget);
      expect(find.text('アップデートが必要です'), findsOneWidget);
    });

    testWidgets('isForced=falseでは「あとで」ボタン表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColorsExtension.light]),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: const Scaffold(
            body: ForceUpdateDialog(
              isForced: false,
              storeUrl: 'https://example.com',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('あとで'), findsOneWidget);
      expect(find.text('アップデート'), findsOneWidget);
      expect(find.text('アップデートが必要です'), findsOneWidget);
    });
  });
}
