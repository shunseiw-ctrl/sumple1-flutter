import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/animated_page_indicator.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AnimatedPageIndicator', () {
    testWidgets('shows correct number of dots', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const AnimatedPageIndicator(
          pageCount: 3,
          currentPage: 0,
        ),
      ));

      final dots = find.byType(AnimatedContainer);
      expect(dots, findsNWidgets(3));
    });

    testWidgets('active dot has wider width (24px)', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const AnimatedPageIndicator(
          pageCount: 3,
          currentPage: 1,
        ),
      ));

      // The active dot (index 1) should have width 24
      // AnimatedContainer uses width/height directly, check via BoxConstraints
      // Instead, verify the rendered size
      final activeElement = tester.elementList(find.byType(AnimatedContainer)).elementAt(1);
      final renderBox = activeElement.renderObject as RenderBox;
      // 24px width + 4px margin * 2 = 32px total render size
      expect(renderBox.size.width, 32.0);
    });

    testWidgets('changing currentPage updates indicator', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const AnimatedPageIndicator(
          pageCount: 3,
          currentPage: 0,
        ),
      ));

      // First dot active (width 24 + margin 8 = 32)
      var elements = tester.elementList(find.byType(AnimatedContainer)).toList();
      var firstBox = elements[0].renderObject as RenderBox;
      expect(firstBox.size.width, 32.0);

      // Change to page 2
      await tester.pumpWidget(buildTestApp(
        const AnimatedPageIndicator(
          pageCount: 3,
          currentPage: 2,
        ),
      ));
      await tester.pumpAndSettle();

      elements = tester.elementList(find.byType(AnimatedContainer)).toList();
      // First dot should now be inactive (width 8 + margin 8 = 16)
      firstBox = elements[0].renderObject as RenderBox;
      expect(firstBox.size.width, 16.0);

      // Third dot should be active (width 24 + margin 8 = 32)
      final thirdBox = elements[2].renderObject as RenderBox;
      expect(thirdBox.size.width, 32.0);
    });

    testWidgets('active dot uses custom activeColor', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(buildTestApp(
        const AnimatedPageIndicator(
          pageCount: 3,
          currentPage: 0,
          activeColor: customColor,
        ),
      ));

      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList();

      // The active dot (index 0) should use the custom color
      final activeContainer = containers[0];
      final decoration = activeContainer.decoration as BoxDecoration;
      expect(decoration.color, customColor);
    });
  });
}
