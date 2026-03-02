import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/gradient_header.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('GradientHeader', () {
    testWidgets('shows title text', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const GradientHeader(title: 'テストタイトル'),
      ));

      expect(find.text('テストタイトル'), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const GradientHeader(
          title: 'タイトル',
          subtitle: 'サブタイトルテスト',
        ),
      ));

      expect(find.text('サブタイトルテスト'), findsOneWidget);
    });

    testWidgets('action button works', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildTestApp(
        GradientHeader(
          title: 'タイトル',
          action: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.settings));
      expect(tapped, isTrue);
    });

    testWidgets('has gradient background decoration', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const GradientHeader(title: 'グラデーション'),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      expect(decoration.gradient, isA<LinearGradient>());
    });
  });
}
