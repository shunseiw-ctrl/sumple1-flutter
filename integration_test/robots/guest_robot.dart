import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ゲストユーザーの操作を抽象化するロボット
class GuestRobot {
  final WidgetTester tester;

  GuestRobot(this.tester);

  /// オンボーディング画面が表示されていることを確認
  Future<void> verifyOnboardingVisible() async {
    // オンボーディングのスキップ or 完了ボタンを探す
    expect(find.byType(PageView), findsOneWidget);
  }

  /// オンボーディングを完了する
  Future<void> completeOnboarding() async {
    // スワイプで最後のページまで進む
    for (int i = 0; i < 3; i++) {
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
    }

    // 「始める」ボタンをタップ
    final startButton = find.text('始める');
    if (startButton.evaluate().isNotEmpty) {
      await tester.tap(startButton);
      await tester.pumpAndSettle();
    }
  }

  /// ゲストとして閲覧開始
  Future<void> startAsGuest() async {
    final guestButton = find.text('ゲストとして見る');
    if (guestButton.evaluate().isNotEmpty) {
      await tester.tap(guestButton);
      await tester.pumpAndSettle();
    }
  }

  /// 求人一覧が表示されていることを確認
  Future<void> verifyJobListVisible() async {
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(ListView), findsWidgets);
  }

  /// 求人をタップして詳細を開く
  Future<void> tapFirstJob() async {
    final listItems = find.byType(InkWell);
    if (listItems.evaluate().isNotEmpty) {
      await tester.tap(listItems.first);
      await tester.pumpAndSettle();
    }
  }

  /// 応募ボタンが制限されていることを確認（ゲストは応募不可）
  Future<void> verifyApplyBlocked() async {
    final applyButton = find.text('応募する');
    if (applyButton.evaluate().isNotEmpty) {
      await tester.tap(applyButton);
      await tester.pumpAndSettle();
      // 登録を促すダイアログが表示されるはず
      expect(
        find.textContaining('登録'),
        findsWidgets,
      );
    }
  }

  /// 戻る
  Future<void> goBack() async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
}
