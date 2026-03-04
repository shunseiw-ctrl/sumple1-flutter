import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/presentation/widgets/job_card.dart';

Widget buildTestApp(Widget child) {
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
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('JobCard NEW badge', () {
    testWidgets('shows NEW badge for recent job', (tester) async {
      await tester.pumpWidget(buildTestApp(
        JobCard(
          title: 'テスト案件',
          location: '東京都',
          dateText: '2026-03-02',
          priceText: '15,000',
          badges: const [],
          showLegacyWarning: false,
          data: {
            'createdAt': DateTime.now(),
            'slots': '5',
            'applicantCount': '0',
          },
          isOwner: false,
          onTap: () {},
          onEdit: null,
          onDelete: null,
        ),
      ));
      await tester.pump();
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('does not show NEW badge for old job', (tester) async {
      await tester.pumpWidget(buildTestApp(
        JobCard(
          title: 'テスト案件',
          location: '東京都',
          dateText: '2026-03-02',
          priceText: '15,000',
          badges: const [],
          showLegacyWarning: false,
          data: {
            'createdAt': DateTime.now().subtract(const Duration(hours: 48)),
            'slots': '5',
            'applicantCount': '0',
          },
          isOwner: false,
          onTap: () {},
          onEdit: null,
          onDelete: null,
        ),
      ));
      await tester.pump();
      expect(find.text('NEW'), findsNothing);
    });
  });
}
