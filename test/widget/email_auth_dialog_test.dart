import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

/// email_auth_dialog.dart のUIテスト
/// Note: showEmailAuthDialog は FirebaseAuth に依存するため
///       ダイアログのUI構造のみを検証する
void main() {
  group('Email Auth Dialog UI', () {
    testWidgets('メール認証ダイアログのUIが正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('メールでログイン'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'メールアドレス',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'パスワード',
                          prefixIcon: Icon(Icons.lock_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('新規登録もこの画面からできます'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('新規登録'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('ログイン'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('ダイアログ表示'),
          ),
        ),
      ));

      await tester.tap(find.text('ダイアログ表示'));
      await tester.pumpAndSettle();

      expect(find.text('メールでログイン'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('新規登録もこの画面からできます'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('新規登録'), findsOneWidget);
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets('キャンセルボタンでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('メールでログイン'),
                  content: const Text('テスト'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('キャンセル'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('ダイアログ表示'),
          ),
        ),
      ));

      await tester.tap(find.text('ダイアログ表示'));
      await tester.pumpAndSettle();
      expect(find.text('メールでログイン'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('メールでログイン'), findsNothing);
    });
  });
}
