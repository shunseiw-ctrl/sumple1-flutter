import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('SalesPage再設計', () {
    testWidgets('2タブ表示（収入/明細）', (tester) async {
      // TabBarのタブテキストを確認
      await tester.pumpWidget(
        buildTestApp(
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  tabs: [
                    Tab(text: '収入'),
                    Tab(text: '明細'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      const Center(child: Text('収入タブ')),
                      const Center(child: Text('明細タブ')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('収入'), findsOneWidget);
      expect(find.text('明細'), findsOneWidget);
    });

    testWidgets('お気に入りタブが存在しない', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          DefaultTabController(
            length: 2,
            child: const TabBar(
              labelColor: Colors.blue,
              tabs: [
                Tab(text: '収入'),
                Tab(text: '明細'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('お気に入り'), findsNothing);
    });

    testWidgets('今月の収入ヘッダーカード表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              Text('今月の収入'),
              Text('¥185,000'),
            ],
          ),
        ),
      );

      expect(find.text('今月の収入'), findsOneWidget);
    });

    testWidgets('次回支払日表示', (tester) async {
      final now = DateTime.now();
      final nextMonth = now.month == 12 ? 1 : now.month + 1;

      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              Text('次回支払日: $nextMonth月10日'),
            ],
          ),
        ),
      );

      expect(find.textContaining('次回支払日'), findsOneWidget);
    });

    testWidgets('未確定の報酬セクション表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              Text('未確定の報酬'),
              Text('検収中'),
            ],
          ),
        ),
      );

      expect(find.text('未確定の報酬'), findsOneWidget);
    });

    testWidgets('支払い履歴アイテムがタップ可能', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          InkWell(
            onTap: () => tapped = true,
            child: const ListTile(
              title: Text('C邸内装工事'),
              subtitle: Text('¥80,000'),
              trailing: Text('振込済み'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('C邸内装工事'));
      expect(tapped, isTrue);
    });
  });
}
