import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 認証済みユーザーの操作を抽象化するロボット
class UserRobot {
  final WidgetTester tester;

  UserRobot(this.tester);

  /// メール/パスワードでログイン
  Future<void> loginWithEmail(String email, String password) async {
    // メール入力
    final emailField = find.byType(TextField).first;
    await tester.enterText(emailField, email);

    // パスワード入力
    final passwordFields = find.byType(TextField);
    if (passwordFields.evaluate().length > 1) {
      await tester.enterText(passwordFields.at(1), password);
    }

    // ログインボタンタップ
    final loginButton = find.text('ログイン');
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
  }

  /// ホームが表示されていることを確認
  Future<void> verifyHomeVisible() async {
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  }

  /// 求人検索
  Future<void> searchJobs(String keyword) async {
    final searchField = find.byType(TextField);
    if (searchField.evaluate().isNotEmpty) {
      await tester.enterText(searchField.first, keyword);
      await tester.pumpAndSettle();
    }
  }

  /// ボトムナビゲーションのタブをタップ
  Future<void> tapBottomTab(int index) async {
    final bottomNav = find.byType(BottomNavigationBar);
    if (bottomNav.evaluate().isNotEmpty) {
      final items = find.descendant(
        of: bottomNav,
        matching: find.byType(InkResponse),
      );
      if (items.evaluate().length > index) {
        await tester.tap(items.at(index));
        await tester.pumpAndSettle();
      }
    }
  }

  /// チャット画面が表示されていることを確認
  Future<void> verifyChatVisible() async {
    expect(find.text('メッセージ'), findsWidgets);
  }

  /// 戻る
  Future<void> goBack() async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
}
