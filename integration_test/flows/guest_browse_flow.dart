import 'package:flutter_test/flutter_test.dart';
import '../robots/guest_robot.dart';

/// ゲスト閲覧フロー: オンボーディング → 求人一覧 → 詳細 → 応募ブロック確認
Future<void> guestBrowseFlow(WidgetTester tester) async {
  final robot = GuestRobot(tester);

  // 1. オンボーディングを完了
  await robot.completeOnboarding();

  // 2. ゲストとして閲覧開始
  await robot.startAsGuest();

  // 3. 求人一覧が表示されることを確認
  await robot.verifyJobListVisible();

  // 4. 最初の求人をタップ
  await robot.tapFirstJob();

  // 5. ゲストは応募がブロックされることを確認
  await robot.verifyApplyBlocked();

  // 6. 戻る
  await robot.goBack();
}
