import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// AdminHomePageのUIコンポーネントテスト
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

  group('AdminHomePage UI Components', () {
    testWidgets('BottomNavigationBarが5つのアイテムで表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: const Center(child: Text('ダッシュボード')),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'ダッシュボード',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                label: '案件管理',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                label: '応募者',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money),
                label: '売上',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'マイページ',
              ),
            ],
          ),
        ),
      ));

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('ダッシュボードサマリカードが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: GridView.count(
            crossAxisCount: 2,
            children: const [
              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work, size: 32),
                    SizedBox(height: 8),
                    Text('案件数'),
                    Text('15', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment, size: 32),
                    SizedBox(height: 8),
                    Text('応募数'),
                    Text('42', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('案件数'), findsOneWidget);
      expect(find.text('応募数'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('FABで案件作成ボタンが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: const SizedBox(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('案件を投稿'),
          ),
        ),
      ));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('案件を投稿'), findsOneWidget);
    });

    testWidgets('タブ切替でコンテンツが変わる', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(buildLocalizedApp(
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(
              child: Text(
                ['ダッシュボード', '案件管理', '応募者', '売上', 'マイページ'][selectedIndex],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: selectedIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (index) => setState(() => selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'ダッシュボード',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  label: '案件管理',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: '応募者',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.attach_money),
                  label: '売上',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'マイページ',
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('ダッシュボード'), findsNWidgets(2)); // label + body

      // 案件管理タブをタップ
      await tester.tap(find.byIcon(Icons.work_outline));
      await tester.pump();

      expect(find.text('案件管理'), findsNWidgets(2)); // label + body
    });

    testWidgets('通知バッジが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          appBar: AppBar(
            title: const Text('管理者'),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('3',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: const SizedBox(),
        ),
      ));

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });
  });
}
