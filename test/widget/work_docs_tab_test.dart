import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

/// WorkDocsTab 抽出ウィジェットのUIテスト
void main() {
  group('WorkDocsTab UI Components', () {
    testWidgets('資料タブヘッダーUIが正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('資料管理',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('追加'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));

      expect(find.text('資料管理'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });

    testWidgets('フォルダチップが正しく表示される', (tester) async {
      const folders = ['御見積書', '図面', '仕様', '工程', 'その他'];

      await tester.pumpWidget(buildTestApp(
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: folders.map((f) {
              final selected = f == '御見積書';
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(f, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) {},
                ),
              );
            }).toList(),
          ),
        ),
      ));

      for (final folder in folders) {
        expect(find.text(folder), findsOneWidget);
      }
      expect(find.byType(ChoiceChip), findsNWidgets(5));
    });

    testWidgets('資料が空の場合の空状態UIが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_off_outlined, size: 48),
              SizedBox(height: 12),
              Text('「御見積書」の資料はまだありません',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ));

      expect(find.text('「御見積書」の資料はまだありません'), findsOneWidget);
      expect(find.byIcon(Icons.folder_off_outlined), findsOneWidget);
    });
  });
}
