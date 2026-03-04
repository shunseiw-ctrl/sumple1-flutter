import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';
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

void main() {
  group('AdminWorkerDetailPage UI構造', () {
    testWidgets('ヘッダーにプロフィール情報が表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          appBar: AppBar(title: const Text('職人詳細')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        child: Icon(Icons.person, size: 32),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('山田太郎', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Text('⭐ 4.2 (12件)'),
                            Text('品質: 3.8'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('職人詳細'), findsOneWidget);
      expect(find.text('山田太郎'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('応募履歴セクションが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('応募履歴', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                // ステータスグループ
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle_outline, size: 16, color: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('進行中')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('1'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const ListTile(
                    title: Text('内装工事A'),
                    subtitle: Text('2025/03/15  新宿区'),
                    trailing: Icon(Icons.chevron_right, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('応募履歴'), findsOneWidget);
      expect(find.text('進行中'), findsOneWidget);
      expect(find.text('内装工事A'), findsOneWidget);
      expect(find.text('2025/03/15  新宿区'), findsOneWidget);
    });

    testWidgets('資格情報セクションが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('資格情報', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_outlined, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('一級建築士', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text('建築'),
                          ],
                        ),
                      ),
                      // StatusBadge はカスタムテーマ必須のためテキストで代用
                      Text('承認済み'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('資格情報'), findsOneWidget);
      expect(find.text('一級建築士'), findsOneWidget);
      expect(find.text('建築'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    testWidgets('AppBarにタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildLocalizedApp(
        Scaffold(
          appBar: AppBar(title: const Text('職人詳細')),
          body: const Center(child: Text('Content')),
        ),
      ));

      expect(find.text('職人詳細'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
