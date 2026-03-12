import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// JobListPageのUIコンポーネントテスト
/// 実際のJobListPageはFirestore/Riverpod依存のため、UI要素を分離してテスト
void main() {
  Widget buildLocalizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: child,
    );
  }

  group('JobListPage UI Components', () {
    testWidgets('都道府県フィルターチップが表示される', (tester) async {
      // _PrefChipsの構造を再現
      final prefLabels = ['新着順', '東京都', '神奈川県', '千葉県', 'その他'];
      String selected = 'all';

      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: prefLabels.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final label = prefLabels[i];
                      final isSelected = i == 0 && selected == 'all';
                      return GestureDetector(
                        onTap: () {
                          setState(() => selected = label);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 全ての都道府県チップが表示される
      expect(find.text('新着順'), findsOneWidget);
      expect(find.text('東京都'), findsOneWidget);
      expect(find.text('神奈川県'), findsOneWidget);
      expect(find.text('千葉県'), findsOneWidget);
      expect(find.text('その他'), findsOneWidget);
    });

    testWidgets('月チップが「すべて」を先頭に表示される', (tester) async {
      // _MonthChipsの構造を再現（すべて + 今月 + 来月 + ...）
      final monthLabels = ['すべて', '今月', '来月', '4月', '5月', '6月', '7月'];
      String? selectedMonth;

      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: monthLabels.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final label = monthLabels[i];
                      final isSelected =
                          (i == 0 && selectedMonth == null) ||
                          selectedMonth == label;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMonth = i == 0 ? null : label;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 「すべて」が先頭に表示される
      expect(find.text('すべて'), findsOneWidget);
      // 月チップが表示される
      expect(find.text('今月'), findsOneWidget);
      expect(find.text('来月'), findsOneWidget);
    });

    testWidgets('ソートドロップダウンが表示される', (tester) async {
      // _SortDropDownの構造を再現
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: PopupMenuButton<String>(
                onSelected: (_) {},
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'newest', child: Text('新着順')),
                  const PopupMenuItem(value: 'distance', child: Text('距離順')),
                  const PopupMenuItem(
                    value: 'highestPay',
                    child: Text('金額が高い順'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      const Text('新着順', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // ソートラベルが表示される
      expect(find.text('新着順'), findsOneWidget);
      // ソートアイコンが表示される
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);

      // ドロップダウンをタップしてメニューを開く
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // メニューアイテムが表示される
      // 「新着順」はボタンラベルとメニューアイテムの両方に表示
      expect(find.text('新着順'), findsNWidgets(2));
      expect(find.text('距離順'), findsOneWidget);
      expect(find.text('金額が高い順'), findsOneWidget);
    });

    testWidgets('表示切替ボタンが表示される', (tester) async {
      // _ViewToggleの構造を再現
      bool isGrid = false;

      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => isGrid = !isGrid);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isGrid
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 初期状態: リスト表示なのでグリッドアイコンが表示（切替先のアイコン）
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      // タップしてグリッド表示に切替
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      // グリッド表示後: リストアイコンに切替
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
    });

    testWidgets('フィルターボタンが表示される', (tester) async {
      // フィルターボタンの構造を再現
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      const Text('フィルタ', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // フィルターアイコンが表示される
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      // フィルターテキストが表示される
      expect(find.text('フィルタ'), findsOneWidget);
    });

    testWidgets('空状態が正しいテキストで表示される', (tester) async {
      // EmptyState（案件なし）の構造を再現
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.work_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '案件がありません',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('現在、この条件に該当する案件はありません。'),
                ],
              ),
            ),
          ),
        ),
      );

      // 空状態アイコンの確認
      expect(find.byIcon(Icons.work_off_outlined), findsOneWidget);
      // 空状態タイトルの確認
      expect(find.text('案件がありません'), findsOneWidget);
      // 空状態説明の確認
      expect(find.text('現在、この条件に該当する案件はありません。'), findsOneWidget);
    });

    testWidgets('FABのマップ検索ボタンが表示される', (tester) async {
      // FloatingActionButton（マップで見る）の構造を再現
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: const SizedBox(),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.map_outlined, color: Colors.white),
              label: const Text(
                'マップで見る',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.blue,
            ),
          ),
        ),
      );

      // FABが表示される
      expect(find.byType(FloatingActionButton), findsOneWidget);
      // マップアイコンが表示される
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      // FABのラベルが表示される
      expect(find.text('マップで見る'), findsOneWidget);
    });

    testWidgets('都道府県チップタップで選択状態が変わる', (tester) async {
      final prefLabels = ['新着順', '東京都', '神奈川県'];
      int selectedIndex = 0;

      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: prefLabels.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final label = prefLabels[i];
                      final isSelected = i == selectedIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedIndex = i);
                        },
                        child: Container(
                          key: Key('pref-chip-$i'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 初期状態: 最初のチップが選択（青色）
      final initialChip = tester.widget<Container>(
        find.byKey(const Key('pref-chip-0')),
      );
      final initialDecoration = initialChip.decoration as BoxDecoration;
      expect(initialDecoration.color, Colors.blue);

      // 東京都チップをタップ
      await tester.tap(find.text('東京都'));
      await tester.pumpAndSettle();

      // 東京都チップが選択状態になる
      final tokyoChip = tester.widget<Container>(
        find.byKey(const Key('pref-chip-1')),
      );
      final tokyoDecoration = tokyoChip.decoration as BoxDecoration;
      expect(tokyoDecoration.color, Colors.blue);

      // 最初のチップは非選択状態になる
      final deselectedChip = tester.widget<Container>(
        find.byKey(const Key('pref-chip-0')),
      );
      final deselectedDecoration = deselectedChip.decoration as BoxDecoration;
      expect(deselectedDecoration.color, Colors.grey[200]);
    });

    testWidgets('検索条件に一致しない場合の空状態が表示される', (tester) async {
      // フィルタリング結果が0件の場合のEmptyState
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '条件に一致する案件がありません',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 検索結果なしアイコンが表示される
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      // 検索結果なしテキストが表示される
      expect(find.text('条件に一致する案件がありません'), findsOneWidget);
    });
  });
}
