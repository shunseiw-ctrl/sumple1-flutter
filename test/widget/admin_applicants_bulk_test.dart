import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/admin/admin_applicants_tab.dart';

void main() {
  group('AdminApplicantsTab bulk operations', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(extensions: const [AppColorsExtension.light]),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(body: AdminApplicantsTab()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AdminApplicantsTab), findsOneWidget);
    });

    testWidgets('page structure is valid', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(extensions: const [AppColorsExtension.light]),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(body: AdminApplicantsTab()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AdminApplicantsTab), findsOneWidget);
    });
  });
}
