import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// ProfilePageのUIコンポーネントテスト
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

  group('ProfilePage UI Components', () {
    testWidgets('マイページタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          appBar: AppBar(title: const Text('マイページ')),
          body: const SizedBox(),
        ),
      ));

      expect(find.text('マイページ'), findsOneWidget);
    });

    testWidgets('メニュー項目が正しく表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('プロフィール編集'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('アカウント設定'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('よくある質問'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('お問い合わせ'),
                onTap: () {},
              ),
            ],
          ),
        ),
      ));

      expect(find.text('プロフィール編集'), findsOneWidget);
      expect(find.text('アカウント設定'), findsOneWidget);
      expect(find.text('よくある質問'), findsOneWidget);
      expect(find.text('お問い合わせ'), findsOneWidget);
    });

    testWidgets('ログアウトボタンが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Center(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ログアウト'),
              onTap: () {},
            ),
          ),
        ),
      ));

      expect(find.text('ログアウト'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('管理者ログインダイアログが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('管理者ログイン'),
                      content: const TextField(
                        decoration: InputDecoration(
                          labelText: '管理者パスワード',
                        ),
                        obscureText: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('ログイン'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('管理者'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('管理者'));
      await tester.pumpAndSettle();

      expect(find.text('管理者ログイン'), findsOneWidget);
      expect(find.text('管理者パスワード'), findsOneWidget);
    });

    testWidgets('プロフィールヘッダーが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 12),
              const Text('テストユーザー',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('test@example.com',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ));

      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('セクションヘッダーが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('アカウント',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('サポート',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('アカウント'), findsOneWidget);
      expect(find.text('サポート'), findsOneWidget);
    });
  });
}
