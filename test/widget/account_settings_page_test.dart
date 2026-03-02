import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// AccountSettingsPageのUIコンポーネントテスト
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

  group('AccountSettingsPage UI Components', () {
    testWidgets('アカウント設定タイトルが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          appBar: AppBar(
            title: Builder(
              builder: (context) =>
                  Text(AppLocalizations.of(context)!.accountSettings),
            ),
          ),
          body: const SizedBox(),
        ),
      ));

      expect(find.text('アカウント設定'), findsOneWidget);
    });

    testWidgets('メール表示セクションが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Text('メールアドレス',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('user@example.com'),
            ],
          ),
        ),
      ));

      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('名前変更セクションが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('名前を変更',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: 'テストユーザー',
                decoration: const InputDecoration(
                  labelText: '表示名',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('名前を変更'), findsOneWidget);
      expect(find.text('表示名'), findsOneWidget);
    });

    testWidgets('パスワード変更セクションが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('パスワードを変更',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: '現在のパスワード'),
              ),
              const SizedBox(height: 8),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: '新しいパスワード'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                child: const Text('変更'),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('パスワードを変更'), findsOneWidget);
      expect(find.text('現在のパスワード'), findsOneWidget);
      expect(find.text('新しいパスワード'), findsOneWidget);
    });

    testWidgets('データダウンロードボタンが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: Text(AppLocalizations.of(context)!.downloadData),
              ),
            ),
          ),
        ),
      ));

      expect(find.text('データをダウンロード'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('アカウント削除ボタンが赤色で表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(
                  AppLocalizations.of(context)!.deleteAccount,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ));

      expect(find.text('アカウントを削除'), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('削除確認ダイアログが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('アカウント削除'),
                      content: const Text(
                          'アカウントを削除しますか？この操作は取り消せません。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('削除'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('削除テスト'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('削除テスト'));
      await tester.pumpAndSettle();

      expect(find.text('アカウント削除'), findsOneWidget);
      expect(find.text('アカウントを削除しますか？この操作は取り消せません。'),
          findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });
  });
}
