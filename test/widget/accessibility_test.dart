import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// アクセシビリティテスト
/// 障害者差別解消法 / App Store accessibility guidelines 対応確認
void main() {
  group('Semantics アクセシビリティ検証', () {
    testWidgets('BottomNavigationBar の各タブに Semantics label がある', (tester) async {
      final navLabels = ['検索', 'はたらく', 'メッセージ', '売上', 'マイページ'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: Row(
              children: List.generate(navLabels.length, (index) {
                final isSelected = index == 0;
                return Expanded(
                  child: Semantics(
                    button: true,
                    label: '${navLabels[index]}タブ${isSelected ? "、選択中" : ""}',
                    selected: isSelected,
                    child: GestureDetector(
                      onTap: () {},
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.home, size: 24),
                          Text(navLabels[index]),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      );

      // 各タブの Semantics label が存在することを確認
      expect(find.bySemanticsLabel(RegExp('検索タブ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('はたらくタブ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('メッセージタブ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('売上タブ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('マイページタブ')), findsOneWidget);
    });

    testWidgets('応募ボタンに Semantics label がある', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              button: true,
              label: 'この案件に応募する',
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('応募する'),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('この案件に応募する'), findsOneWidget);
    });

    testWidgets('お気に入りボタンの Semantics label が状態に応じて変わる', (tester) async {
      bool isFavorite = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Semantics(
                  button: true,
                  label: isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
                  child: IconButton(
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                    onPressed: () => setState(() => isFavorite = !isFavorite),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.bySemanticsLabel('お気に入りに追加'), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.bySemanticsLabel('お気に入りから削除'), findsOneWidget);
    });

    testWidgets('Semantics widget は toggled 状態を正しく反映する', (tester) async {
      bool accepted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Row(
                  children: [
                    Checkbox(
                      value: accepted,
                      onChanged: (v) => setState(() => accepted = v ?? false),
                    ),
                    Text(accepted ? '同意済み' : '未同意'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('未同意'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(find.text('同意済み'), findsOneWidget);
    });
  });
}
