import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/pages/profile/profile_widgets.dart';
import '../helpers/test_helpers.dart';

/// profile_widgets.dart 抽出ウィジェットのUIテスト
void main() {
  group('ProfileHeaderCard', () {
    testWidgets('ログイン済みユーザーのヘッダーが正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const ProfileHeaderCard(
          displayName: 'テストユーザー',
          subtitle: 'ログイン済み',
          isLoggedIn: true,
        ),
      ));

      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('ログイン済み'), findsAtLeast(1));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('ゲストユーザーのヘッダーが正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const ProfileHeaderCard(
          displayName: 'ゲスト',
          subtitle: 'ログインすると応募・チャットが使えます',
          isLoggedIn: false,
        ),
      ));

      expect(find.text('ゲスト'), findsAtLeast(1));
      expect(find.text('ログインすると応募・チャットが使えます'), findsOneWidget);
    });
  });

  group('ProfileSectionHeader / ProfileMenuGroup / ProfileMenuTile', () {
    testWidgets('セクションヘッダーが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const Column(
          children: [
            ProfileSectionHeader(title: 'アカウント'),
            ProfileSectionHeader(title: 'サポート'),
          ],
        ),
      ));

      // toUpperCase で表示される
      expect(find.textContaining('アカウント'), findsOneWidget);
      expect(find.textContaining('サポート'), findsOneWidget);
    });

    testWidgets('メニュータイルが正しく表示される', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestApp(
        ProfileMenuGroup(
          children: [
            ProfileMenuTile(
              icon: Icons.settings_outlined,
              iconColor: Colors.blue,
              title: 'アカウント設定',
              onTap: () => tapped = true,
            ),
            ProfileMenuTile(
              icon: Icons.help_outline,
              iconColor: Colors.orange,
              title: 'よくある質問',
              subtitle: 'ヘルプセンター',
              isLast: true,
              onTap: () {},
            ),
          ],
        ),
      ));

      expect(find.text('アカウント設定'), findsOneWidget);
      expect(find.text('よくある質問'), findsOneWidget);
      expect(find.text('ヘルプセンター'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);

      await tester.tap(find.text('アカウント設定'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
