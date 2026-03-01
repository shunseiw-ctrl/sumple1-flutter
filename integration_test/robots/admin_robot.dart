import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 管理者ユーザーの操作を抽象化するロボット
class AdminRobot {
  final WidgetTester tester;

  AdminRobot(this.tester);

  /// 管理者ダッシュボードが表示されていることを確認
  Future<void> verifyAdminDashboardVisible() async {
    await tester.pumpAndSettle(const Duration(seconds: 3));
    // admin_home_page には統計カードがある
    expect(find.byType(TabBar), findsWidgets);
  }

  /// 求人作成画面を開く
  Future<void> openPostPage() async {
    final addButton = find.byIcon(Icons.add);
    if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton.first);
      await tester.pumpAndSettle();
    }
  }

  /// 求人フォームに入力
  Future<void> fillJobForm({
    required String title,
    required String location,
    required String price,
  }) async {
    final textFields = find.byType(TextFormField);

    if (textFields.evaluate().isNotEmpty) {
      // タイトル入力
      await tester.enterText(textFields.first, title);

      // 場所入力
      if (textFields.evaluate().length > 1) {
        await tester.enterText(textFields.at(1), location);
      }

      // 価格入力
      if (textFields.evaluate().length > 2) {
        await tester.enterText(textFields.at(2), price);
      }
    }
  }

  /// 応募管理タブを開く
  Future<void> openApplicationsTab() async {
    final tab = find.text('応募管理');
    if (tab.evaluate().isNotEmpty) {
      await tester.tap(tab);
      await tester.pumpAndSettle();
    }
  }

  /// 戻る
  Future<void> goBack() async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
}
