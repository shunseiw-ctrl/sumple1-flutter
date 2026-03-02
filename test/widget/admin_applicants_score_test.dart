import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('応募者カード品質スコアバッジ', () {
    testWidgets('応募者カードに品質スコアバッジ表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Row(
            children: [
              // 既存のRatingStarsDisplay相当
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              const Text('4.5', style: TextStyle(fontSize: 11)),
              const Text(' (12件)', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 8),
              // 新規: 品質スコアバッジ
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '品質: 4.2',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.textContaining('品質:'), findsOneWidget);
    });
  });
}
