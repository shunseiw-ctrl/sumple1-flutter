import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/pages/profile/profile_widgets.dart';

Widget buildTestApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('Profile Header Gradient', () {
    testWidgets('ProfileHeaderCard renders correctly', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const ProfileHeaderCard(
          displayName: 'テストユーザー',
          subtitle: 'ログイン済み',
          isLoggedIn: true,
        ),
      ));
      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('ログイン済み'), findsAtLeast(1));
    });

    testWidgets('ProfileMenuGroup renders menu items', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ProfileMenuGroup(
          children: [
            ProfileMenuTile(
              icon: Icons.settings,
              iconColor: Colors.blue,
              title: 'テストメニュー',
              onTap: () {},
              isLast: true,
            ),
          ],
        ),
      ));
      expect(find.text('テストメニュー'), findsOneWidget);
    });
  });
}
