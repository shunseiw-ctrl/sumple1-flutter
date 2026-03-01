import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/rating_stars_display.dart';

void main() {
  group('RatingStarsDisplay', () {
    testWidgets('評価0件で「評価なし」テキストを表示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStarsDisplay(average: 0, count: 0),
          ),
        ),
      );

      expect(find.text('評価なし'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('評価5.0で全て塗りつぶし星', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStarsDisplay(average: 5.0, count: 10),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.star_half_rounded), findsNothing);
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    });

    testWidgets('評価3.5で半星が含まれる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStarsDisplay(average: 3.5, count: 5),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('スコアテキストが表示される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStarsDisplay(average: 4.2, count: 15),
          ),
        ),
      );

      expect(find.text('4.2'), findsOneWidget);
      expect(find.text('(15件)'), findsOneWidget);
    });

    testWidgets('評価1.0で星1つ塗り、4つ空', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingStarsDisplay(average: 1.0, count: 1),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(4));
    });
  });
}
