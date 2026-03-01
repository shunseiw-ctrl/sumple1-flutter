import 'package:flutter_test/flutter_test.dart';
import '../robots/user_robot.dart';

/// ユーザー応募フロー: ログイン → 求人検索 → 応募 → チャット開始
Future<void> userApplyFlow(WidgetTester tester) async {
  final robot = UserRobot(tester);

  // 1. メールでログイン
  await robot.loginWithEmail('test@example.com', 'password123');

  // 2. ホーム画面が表示されることを確認
  await robot.verifyHomeVisible();

  // 3. 求人を検索
  await robot.searchJobs('内装');

  // 4. メッセージタブを確認
  await robot.tapBottomTab(2);
  await robot.verifyChatVisible();
}
