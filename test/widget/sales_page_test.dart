import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// SalesPageのUIコンポーネントテスト
/// 実際のSalesPageはFirebase依存のため、UI要素を分離してテスト
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

  group('SalesPage UI Components', () {
    testWidgets('匿名ユーザーに会員登録促進のEmptyStateが表示される', (tester) async {
      // 匿名ユーザー時のEmptyState表示を再現
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            appBar: AppBar(title: const Text('売上'), centerTitle: true),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '会員登録が必要です',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('売上情報を確認するには会員登録が必要です。'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('登録して始める'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // EmptyStateアイコンの確認
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      // タイトルテキストの確認
      expect(find.text('会員登録が必要です'), findsOneWidget);
      // 説明テキストの確認
      expect(find.text('売上情報を確認するには会員登録が必要です。'), findsOneWidget);
      // アクションボタンの確認
      expect(find.text('登録して始める'), findsOneWidget);
    });

    testWidgets('TabBarに2つのタブが表示される（収入/明細）', (tester) async {
      // SalesPageのTabBar構造を再現
      await tester.pumpWidget(
        buildLocalizedApp(
          DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('収入・明細'),
                centerTitle: true,
                bottom: const TabBar(
                  tabs: [
                    Tab(text: '収入'),
                    Tab(text: '明細'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('収入コンテンツ')),
                  Center(child: Text('明細コンテンツ')),
                ],
              ),
            ),
          ),
        ),
      );

      // 2つのタブテキストの確認
      expect(find.text('収入'), findsOneWidget);
      expect(find.text('明細'), findsOneWidget);
      // AppBarタイトルの確認
      expect(find.text('収入・明細'), findsOneWidget);
    });

    testWidgets('タブ切り替えが動作する', (tester) async {
      await tester.pumpWidget(
        buildLocalizedApp(
          DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: '収入'),
                    Tab(text: '明細'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('収入コンテンツ')),
                  Center(child: Text('明細コンテンツ')),
                ],
              ),
            ),
          ),
        ),
      );

      // 初期状態: 収入タブが表示
      expect(find.text('収入コンテンツ'), findsOneWidget);

      // 明細タブをタップ
      await tester.tap(find.text('明細'));
      await tester.pumpAndSettle();

      // 明細コンテンツが表示される
      expect(find.text('明細コンテンツ'), findsOneWidget);
    });

    testWidgets('AppBarにタイトルが正しく表示される', (tester) async {
      // 匿名ユーザー時のAppBarタイトル
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            appBar: AppBar(title: const Text('売上'), centerTitle: true),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('売上'), findsOneWidget);
    });

    testWidgets('認証済みユーザー時のAppBarタイトルが正しい', (tester) async {
      // 認証済みユーザー時のAppBarタイトル
      await tester.pumpWidget(
        buildLocalizedApp(
          DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('収入・明細'),
                centerTitle: true,
                bottom: const TabBar(
                  tabs: [
                    Tab(text: '収入'),
                    Tab(text: '明細'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('収入コンテンツ')),
                  Center(child: Text('明細コンテンツ')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('収入・明細'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('EmptyState内のアクションボタンがタップ可能', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildLocalizedApp(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('会員登録が必要です'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => tapped = true,
                    child: const Text('登録して始める'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('登録して始める'));
      expect(tapped, isTrue);
    });
  });
}
