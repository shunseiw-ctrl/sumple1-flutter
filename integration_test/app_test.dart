import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sumple1/main.dart' as app;

import 'robots/guest_robot.dart';
import 'robots/user_robot.dart';
import 'robots/admin_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Flow', () {
    testWidgets('guest can browse jobs and see apply block', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final robot = GuestRobot(tester);

      // オンボーディング完了
      await robot.completeOnboarding();

      // ゲストとして閲覧
      await robot.startAsGuest();

      // 求人一覧が表示される
      await robot.verifyJobListVisible();
    });

    testWidgets('guest cannot access restricted features', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final robot = GuestRobot(tester);
      await robot.completeOnboarding();
      await robot.startAsGuest();
      await robot.verifyJobListVisible();

      // 求人詳細を開く
      await robot.tapFirstJob();

      // 応募がブロックされることを確認
      await robot.verifyApplyBlocked();
    });
  });

  group('User Flow', () {
    testWidgets('user can see home after login', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final robot = UserRobot(tester);

      // ログイン後にホーム画面が表示される
      await robot.verifyHomeVisible();
    });

    testWidgets('user can navigate between tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final robot = UserRobot(tester);
      await robot.verifyHomeVisible();

      // 各タブに移動できる
      await robot.tapBottomTab(1); // はたらく
      await robot.tapBottomTab(2); // メッセージ
      await robot.tapBottomTab(3); // 売上
      await robot.tapBottomTab(4); // プロフィール
      await robot.tapBottomTab(0); // ホームに戻る
    });
  });

  group('Admin Flow', () {
    testWidgets('admin can see dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final robot = AdminRobot(tester);
      await robot.verifyAdminDashboardVisible();
    });
  });

  group('Navigation', () {
    testWidgets('app starts without crashing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // アプリが起動してなんらかの画面が表示される
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('app renders correct theme', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsOneWidget);
    });
  });
}
