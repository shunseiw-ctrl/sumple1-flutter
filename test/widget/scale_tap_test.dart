import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/scale_tap.dart';

void main() {
  group('ScaleTap', () {
    testWidgets('onTap callback is invoked on tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScaleTap(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('uses GestureDetector for tap handling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScaleTap(
              onTap: () {},
              child: const Text('Scale'),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('can be tapped when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScaleTap(
              child: Text('No callback'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('No callback'));
      await tester.pumpAndSettle();

      expect(find.text('No callback'), findsOneWidget);
    });
  });
}
