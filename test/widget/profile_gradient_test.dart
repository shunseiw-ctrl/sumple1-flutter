import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/profile/profile_widgets.dart';

Widget buildTestApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: const [AppColorsExtension.light]),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ja'),
    home: Scaffold(body: child),
  );
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
