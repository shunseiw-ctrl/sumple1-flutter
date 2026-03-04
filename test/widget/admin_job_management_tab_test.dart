import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

Widget _buildLocalizedApp(Widget child) {
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

/// AdminJobManagementTab の UIコンポーネントテスト（Phase 21: 2ビュー切替+WorkPage風7タブ）
void main() {
  group('AdminJobManagementTab UI構造', () {
    testWidgets('SegmentedButtonが2ビューで表示される', (tester) async {
      await tester.pumpWidget(_buildLocalizedApp(
        Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('案件一覧'),
                      icon: Icon(Icons.work_outline, size: 18),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('全応募ステータス'),
                      icon: Icon(Icons.people_outline, size: 18),
                    ),
                  ],
                  selected: const {0},
                  onSelectionChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ));

      expect(find.byType(SegmentedButton<int>), findsOneWidget);
      expect(find.text('案件一覧'), findsOneWidget);
      expect(find.text('全応募ステータス'), findsOneWidget);
    });

    testWidgets('サマリー統計チップが表示される', (tester) async {
      await tester.pumpWidget(_buildLocalizedApp(
        Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('全12件'),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('募集中5件'),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('全12件'), findsOneWidget);
      expect(find.text('募集中5件'), findsOneWidget);
    });

    testWidgets('コンパクト案件カードのレイアウトが正しい', (tester) async {
      await tester.pumpWidget(_buildLocalizedApp(
        Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: const Row(
                children: [
                  Expanded(child: Text('内装工事A')),
                  Text('¥15,000'),
                ],
              ),
              subtitle: const Row(
                children: [
                  Text('応募中'),
                  SizedBox(width: 8),
                  Icon(Icons.event, size: 12),
                  Text('3/15'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {},
            ),
          ),
        ),
      ));

      expect(find.text('内装工事A'), findsOneWidget);
      expect(find.text('¥15,000'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('全応募ステータスビューのTabBarが8タブで表示される', (tester) async {
      await tester.pumpWidget(_buildLocalizedApp(
        DefaultTabController(
          length: 8,
          child: Scaffold(
            body: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'すべて'),
                    Tab(text: '応募中'),
                    Tab(text: 'アサイン済み'),
                    Tab(text: '作業中'),
                    Tab(text: '完了'),
                    Tab(text: '検査中'),
                    Tab(text: '修正中'),
                    Tab(text: '完了'),
                  ],
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('応募中'), findsOneWidget);
      expect(find.text('アサイン済み'), findsOneWidget);
      expect(find.text('作業中'), findsOneWidget);
    });

    testWidgets('FABが表示される', (tester) async {
      await tester.pumpWidget(_buildLocalizedApp(
        Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('案件を投稿'),
          ),
        ),
      ));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('案件を投稿'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('ビュー切り替えが動作する', (tester) async {
      int viewIndex = 0;
      await tester.pumpWidget(_buildLocalizedApp(
        StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('案件一覧')),
                        ButtonSegment(value: 1, label: Text('全応募')),
                      ],
                      selected: {viewIndex},
                      onSelectionChanged: (set) =>
                          setState(() => viewIndex = set.first),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(viewIndex == 0
                          ? 'Jobs View'
                          : 'Applications View'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ));

      expect(find.text('Jobs View'), findsOneWidget);

      await tester.tap(find.text('全応募'));
      await tester.pump();

      expect(find.text('Applications View'), findsOneWidget);
    });
  });
}
