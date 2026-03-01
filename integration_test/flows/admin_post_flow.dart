import 'package:flutter_test/flutter_test.dart';
import '../robots/admin_robot.dart';

/// 管理者投稿フロー: 管理者ログイン → 求人作成 → 応募管理
Future<void> adminPostFlow(WidgetTester tester) async {
  final robot = AdminRobot(tester);

  // 1. 管理者ダッシュボードが表示されることを確認
  await robot.verifyAdminDashboardVisible();

  // 2. 求人作成画面を開く
  await robot.openPostPage();

  // 3. 求人フォームに入力
  await robot.fillJobForm(
    title: 'テスト内装工事',
    location: '東京都渋谷区',
    price: '15000',
  );

  // 4. 戻る
  await robot.goBack();

  // 5. 応募管理タブを確認
  await robot.openApplicationsTab();
}
