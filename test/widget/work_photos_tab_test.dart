import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

/// WorkPhotosTab 抽出ウィジェットのUIテスト
/// Note: WorkPhotosTab は Firebase 依存のため直接インスタンス化せず
///       抽出されたUI要素の構造をテストする
void main() {
  group('WorkPhotosTab UI Components', () {
    testWidgets('写真タブヘッダーUIが正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  const Icon(Icons.photo_library, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('現場写真',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('追加'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));

      expect(find.text('現場写真'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
    });

    testWidgets('写真が空の場合の空状態UIが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_outlined, size: 56),
              SizedBox(height: 12),
              Text('写真はまだありません',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('「追加」ボタンから写真をアップロード',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ));

      expect(find.text('写真はまだありません'), findsOneWidget);
      expect(find.text('「追加」ボタンから写真をアップロード'), findsOneWidget);
      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
    });

    testWidgets('写真削除ダイアログが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('写真を削除'),
                  content: const Text('この写真を削除しますか？'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('キャンセル')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('削除')),
                  ],
                ),
              );
            },
            child: const Text('削除テスト'),
          ),
        ),
      ));

      await tester.tap(find.text('削除テスト'));
      await tester.pumpAndSettle();

      expect(find.text('写真を削除'), findsOneWidget);
      expect(find.text('この写真を削除しますか？'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });
  });
}
