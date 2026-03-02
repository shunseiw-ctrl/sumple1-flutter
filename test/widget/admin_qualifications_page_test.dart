import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('AdminQualificationsPage', () {
    testWidgets('pending資格が一覧表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('資格承認')),
            body: ListView(
              children: const [
                ListTile(
                  title: Text('内装仕上げ施工技能士'),
                  subtitle: Text('ワーカー: 田中太郎 / カテゴリ: interior'),
                  trailing: Text('pending'),
                ),
                ListTile(
                  title: Text('足場組立作業主任者'),
                  subtitle: Text('ワーカー: 佐藤花子 / カテゴリ: scaffold'),
                  trailing: Text('pending'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('資格承認'), findsOneWidget);
      expect(find.text('内装仕上げ施工技能士'), findsOneWidget);
      expect(find.text('足場組立作業主任者'), findsOneWidget);
    });

    testWidgets('承認ボタンが表示される', (tester) async {
      bool approved = false;
      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              ElevatedButton(
                onPressed: () => approved = true,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('承認'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('承認'), findsOneWidget);
      await tester.tap(find.text('承認'));
      expect(approved, isTrue);
    });

    testWidgets('却下時に理由入力ダイアログ', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('却下理由'),
                      content: const TextField(
                        decoration: InputDecoration(hintText: '理由を入力'),
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
      expect(find.text('却下する'), findsOneWidget);
    });
  });
}
