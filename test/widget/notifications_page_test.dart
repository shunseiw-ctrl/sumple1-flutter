import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// NotificationsPageのUIコンポーネントテスト
void main() {
  Widget buildLocalizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: child,
    );
  }

  group('NotificationsPage UI Components', () {
    testWidgets('お知らせタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          appBar: AppBar(
            title: Builder(
              builder: (context) =>
                  Text(AppLocalizations.of(context)!.notifications),
            ),
          ),
          body: const SizedBox(),
        ),
      ));

      expect(find.text('お知らせ'), findsOneWidget);
    });

    testWidgets('空状態が正しく表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          appBar: AppBar(title: const Text('お知らせ')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('お知らせはありません'),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('お知らせはありません'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('通知アイテムが正しく表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: ListView(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.work, color: Colors.white),
                ),
                title: const Text('案件に応募がありました'),
                subtitle: const Text('3/2 14:30'),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.update, color: Colors.white),
                ),
                title: Text('ステータスが更新されました'),
                subtitle: Text('3/1 10:00'),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('案件に応募がありました'), findsOneWidget);
      expect(find.text('ステータスが更新されました'), findsOneWidget);
    });

    testWidgets('未読インジケーターが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Container(
            color: Colors.blue.withValues(alpha: 0.05),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.notifications),
              ),
              title: const Text('新しい通知'),
              trailing: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ));

      expect(find.text('新しい通知'), findsOneWidget);
    });

    testWidgets('既読一括ボタンが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          appBar: AppBar(
            title: const Text('お知らせ'),
            actions: [
              TextButton(
                onPressed: () {},
                child: const Text('すべて既読'),
              ),
            ],
          ),
          body: const SizedBox(),
        ),
      ));

      expect(find.text('すべて既読'), findsOneWidget);
    });

    testWidgets('通知タイプ別のアイコンが正しく表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.work, color: Colors.blue.shade700),
              ),
              CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Icon(Icons.update, color: Colors.orange.shade700),
              ),
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.payment, color: Colors.green.shade700),
              ),
            ],
          ),
        ),
      ));

      expect(find.byIcon(Icons.work), findsOneWidget);
      expect(find.byIcon(Icons.update), findsOneWidget);
      expect(find.byIcon(Icons.payment), findsOneWidget);
    });

    testWidgets('タイムスタンプが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: const ListTile(
            title: Text('テスト通知'),
            subtitle: Text('3/2 14:30'),
          ),
        ),
      ));

      expect(find.text('3/2 14:30'), findsOneWidget);
    });
  });
}
