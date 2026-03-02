import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/onboarding_page.dart';
import 'package:sumple1/presentation/widgets/animated_page_indicator.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() {
    return const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ja'),
      home: OnboardingPage(),
    );
  }

  group('OnboardingPage Enhanced', () {
    testWidgets('logo or fallback text is shown on first page', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Logo image or fallback ALBAWORK text should be present
      final logoImage = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/logo.png',
      );
      final fallbackText = find.text('ALBAWORK');

      // Either the logo image or the fallback text should be shown
      expect(
        logoImage.evaluate().isNotEmpty || fallbackText.evaluate().isNotEmpty,
        isTrue,
        reason: 'Logo image or ALBAWORK fallback text should be shown on first page',
      );
    });

    testWidgets('AnimatedPageIndicator is used', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedPageIndicator), findsOneWidget);
    });
  });
}
