import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumple1/pages/onboarding_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingPage', () {
    testWidgets('renders first page with title and description', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
      await tester.pumpAndSettle();

      expect(find.text('理想の現場を見つけよう'), findsOneWidget);
      expect(find.text('建設業界の豊富な案件から\nあなたにぴったりの仕事が見つかります'), findsOneWidget);
    });

    testWidgets('スキップ button is present', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
      await tester.pumpAndSettle();

      expect(find.text('スキップ'), findsOneWidget);
    });

    testWidgets('次へ button is present on first page', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
      await tester.pumpAndSettle();

      expect(find.text('次へ'), findsOneWidget);
    });

    testWidgets('page indicator shows 3 dots', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
      await tester.pumpAndSettle();

      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsNWidgets(3));
    });
  });
}
