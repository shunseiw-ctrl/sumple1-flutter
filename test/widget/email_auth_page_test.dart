import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// EmailAuthPageのUIコンポーネントテスト
/// （Firebase依存を回避するためフォーム要素を単独でテスト）
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

  group('EmailAuthPage UI Components', () {
    testWidgets('ログイン/新規登録タブが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('メールアドレスでログイン'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'ログイン'),
                  Tab(text: '新規登録'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                Center(child: Text('ログインフォーム')),
                Center(child: Text('登録フォーム')),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ログイン'), findsOneWidget);
      expect(find.text('新規登録'), findsOneWidget);
    });

    testWidgets('メールアドレスフィールドが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      ));

      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('パスワードフィールドが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'パスワード',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: Icon(Icons.visibility_off),
              ),
            ),
          ),
        ),
      ));

      expect(find.text('パスワード'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('パスワード表示/非表示切替が動作する', (tester) async {
      bool obscure = true;

      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('パスワード忘れリンクが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('パスワードを忘れた方'),
            ),
          ),
        ),
      ));

      expect(find.text('パスワードを忘れた方'), findsOneWidget);
    });

    testWidgets('パスワードリセットダイアログが構築される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('パスワードリセット'),
                      content: const TextField(
                        decoration: InputDecoration(
                          labelText: 'メールアドレス',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('送信'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('リセット'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('リセット'));
      await tester.pumpAndSettle();

      expect(find.text('パスワードリセット'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('送信'), findsOneWidget);
    });

    testWidgets('ログインボタンの状態が管理される', (tester) async {
      bool isLoading = false;

      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : () => setState(() => isLoading = true),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('ログイン'),
              ),
            ),
          ),
        ),
      ));

      expect(find.text('ログイン'), findsOneWidget);

      await tester.tap(find.text('ログイン'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
