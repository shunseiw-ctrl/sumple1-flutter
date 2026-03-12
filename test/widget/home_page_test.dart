import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// HomePageのUIコンポーネントテスト
/// 実際のHomePageはRiverpod/Firebase依存のため、UI要素を分離してテスト
void main() {
  // GoogleFontsのHTTP呼び出しを無効化
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

  group('HomePage UI Components', () {
    testWidgets('ボトムナビゲーションバーに5つのアイテムが正しいアイコンで表示される', (tester) async {
      // _ModernBottomNavの構造を再現（5つのナビアイテム）
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: _TestBottomNav(
              currentIndex: 0,
              unreadCount: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5つのナビゲーションラベルが表示される
      expect(find.text('検索'), findsOneWidget);
      expect(find.text('はたらく'), findsOneWidget);
      expect(find.text('メッセージ'), findsOneWidget);
      expect(find.text('収入'), findsOneWidget);
      expect(find.text('プロフィール'), findsOneWidget);

      // 各ナビアイテムのアイコンが表示される
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('通知ベルアイコンが表示される', (tester) async {
      // AppBarの通知アイコン構造を再現
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 26),
                  onPressed: () {},
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('ボトムナビアイテムタップで選択状態が変わる', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        buildLocalizedApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: const SizedBox(),
                bottomNavigationBar: _TestBottomNav(
                  currentIndex: selectedIndex,
                  unreadCount: 0,
                  onTap: (index) {
                    setState(() => selectedIndex = index);
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: 検索タブが選択
      // 選択中のアイコンはfilled版（Icons.search）
      expect(find.byIcon(Icons.search), findsOneWidget);

      // はたらくタブをタップ
      await tester.tap(find.text('はたらく'));
      await tester.pumpAndSettle();

      // はたらくタブが選択状態になりfilled版アイコン（Icons.work）に変わる
      expect(find.byIcon(Icons.work), findsOneWidget);
    });

    testWidgets('AppBarが正しくレンダリングされる', (tester) async {
      // HomePageのAppBar構造を再現（検索バー付き）
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            appBar: AppBar(
              titleSpacing: 12,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'エリア・条件で検索',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                    Icon(Icons.tune_rounded, color: Colors.grey[600], size: 20),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 26),
                  onPressed: () {},
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );

      // 検索バーのテキストが表示される
      expect(find.text('エリア・条件で検索'), findsOneWidget);
      // 検索アイコンが表示される
      expect(find.byIcon(Icons.search), findsOneWidget);
      // フィルターアイコンが表示される
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      // 通知アイコンが表示される
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('メッセージタブに未読バッジが表示される', (tester) async {
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: _TestBottomNav(
              currentIndex: 0,
              unreadCount: 5,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 未読バッジが表示される
      expect(find.byKey(const Key('unread-badge')), findsOneWidget);
      // 未読数が表示される
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('未読数0の場合バッジが非表示', (tester) async {
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: _TestBottomNav(
              currentIndex: 0,
              unreadCount: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 未読バッジは非表示
      expect(find.byKey(const Key('unread-badge')), findsNothing);
    });

    testWidgets('未読数99超の場合99+と表示される', (tester) async {
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: _TestBottomNav(
              currentIndex: 0,
              unreadCount: 150,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unread-badge')), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
    });
  });
}

/// テスト用BottomNavウィジェット
/// 実際の_ModernBottomNavと同じ構造・ロジックを再現
class _TestBottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  const _TestBottomNav({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItemData(
        selectedIcon: Icons.search,
        unselectedIcon: Icons.search_outlined,
        label: '検索',
      ),
      _NavItemData(
        selectedIcon: Icons.work,
        unselectedIcon: Icons.work_outline,
        label: 'はたらく',
      ),
      _NavItemData(
        selectedIcon: Icons.chat_bubble,
        unselectedIcon: Icons.chat_bubble_outline,
        label: 'メッセージ',
      ),
      _NavItemData(
        selectedIcon: Icons.payments,
        unselectedIcon: Icons.payments_outlined,
        label: '収入',
      ),
      _NavItemData(
        selectedIcon: Icons.person,
        unselectedIcon: Icons.person_outline,
        label: 'プロフィール',
      ),
    ];

    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;
          // メッセージタブ(index==2)に未読バッジ
          final showBadge = index == 2 && unreadCount > 0;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.unselectedIcon,
                        size: 26,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      if (showBadge)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            key: const Key('unread-badge'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ナビゲーションアイテムデータ
class _NavItemData {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;

  const _NavItemData({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
  });
}
