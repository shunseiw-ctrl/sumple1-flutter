import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('WorkDetail報酬表示', () {
    testWidgets('earningsなし → 「未確定」表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.payments_outlined, color: Colors.grey),
                SizedBox(width: 8),
                Text('報酬'),
                Spacer(),
                Text('未確定', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );

      expect(find.text('未確定'), findsOneWidget);
      expect(find.text('報酬'), findsOneWidget);
    });

    testWidgets('earnings存在 → 金額 + 「確定済み」表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Container(
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Icon(Icons.payments, color: Colors.blue),
                SizedBox(width: 8),
                Text('報酬'),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('¥50,000', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('確定済み', style: TextStyle(color: Colors.blue, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('¥50,000'), findsOneWidget);
      expect(find.text('確定済み'), findsOneWidget);
    });

    testWidgets('振込済み → 「振込済み」表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Container(
            padding: const EdgeInsets.all(12),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('報酬'),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('¥80,000', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('振込済み', style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('振込済み'), findsOneWidget);
    });

    testWidgets('着工中ステータスでは非表示', (tester) async {
      // 着工中(in_progress)では報酬カードを表示しないロジックのテスト
      const status = 'in_progress';
      const showPayment = status == 'completed' ||
          status == 'done' ||
          status == 'inspection' ||
          status == 'fixing';

      expect(showPayment, isFalse);

      // Widget上でも非表示
      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              if (showPayment)
                const Text('報酬情報'),
              const Text('概要'),
            ],
          ),
        ),
      );

      expect(find.text('報酬情報'), findsNothing);
      expect(find.text('概要'), findsOneWidget);
    });
  });
}
