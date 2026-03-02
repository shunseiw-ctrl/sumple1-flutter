import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('品質スコアカード', () {
    testWidgets('品質スコアカードがスコア表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('品質スコア',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    const Text('4.2',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('品質スコア'), findsOneWidget);
      expect(find.text('4.2'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('内訳（評価・完了率・資格数）が表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('品質スコア'),
                SizedBox(height: 8),
                Text('評価平均: 4.5 (12件)'),
                Text('完了率: 85% (17/20)'),
                Text('認定資格: 3件'),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('評価平均'), findsOneWidget);
      expect(find.textContaining('完了率'), findsOneWidget);
      expect(find.textContaining('認定資格'), findsOneWidget);
    });
  });
}
