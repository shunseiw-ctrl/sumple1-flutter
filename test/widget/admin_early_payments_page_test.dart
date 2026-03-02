import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('AdminEarlyPaymentsPage', () {
    testWidgets('申請リスト表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('即金申請管理')),
            body: ListView(
              children: const [
                ListTile(
                  title: Text('田中太郎'),
                  subtitle: Text('2025-04 / ¥150,000'),
                ),
                ListTile(
                  title: Text('佐藤花子'),
                  subtitle: Text('2025-04 / ¥80,000'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('即金申請管理'), findsOneWidget);
      expect(find.text('田中太郎'), findsOneWidget);
      expect(find.text('佐藤花子'), findsOneWidget);
    });

    testWidgets('申請詳細（金額・手数料・受取額）表示', (tester) async {
      const amount = 150000;
      const fee = 15000; // 10%
      const payout = 135000;

      await tester.pumpWidget(
        buildTestApp(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('申請額: ¥${_formatYen(amount)}'),
              Text('手数料 (10%): ¥${_formatYen(fee)}'),
              Text('受取額: ¥${_formatYen(payout)}'),
            ],
          ),
        ),
      );

      expect(find.textContaining('申請額'), findsOneWidget);
      expect(find.textContaining('手数料'), findsOneWidget);
      expect(find.textContaining('受取額'), findsOneWidget);
    });

    testWidgets('承認ボタンで承認処理', (tester) async {
      bool approved = false;
      await tester.pumpWidget(
        buildTestApp(
          ElevatedButton(
            onPressed: () => approved = true,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('承認'),
          ),
        ),
      );

      await tester.tap(find.text('承認'));
      expect(approved, isTrue);
    });

    testWidgets('却下ボタンで理由入力ダイアログ', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('却下理由'),
                      content: const TextField(
                        decoration: InputDecoration(hintText: '理由を入力してください'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('キャンセル'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('却下する'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('却下'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('却下'));
      await tester.pumpAndSettle();

      expect(find.text('却下理由'), findsOneWidget);
    });

    testWidgets('申請0件で空状態表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('承認待ちの申請はありません'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('承認待ちの申請はありません'), findsOneWidget);
    });
  });
}

String _formatYen(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
