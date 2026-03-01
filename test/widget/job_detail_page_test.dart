import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/pages/job_detail_page.dart';

void main() {
  Widget buildTestWidget(Map<String, dynamic> data) {
    return MaterialApp(
      home: Scaffold(
        body: JobDetailBody(data: data),
      ),
    );
  }

  group('JobDetailBody', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都渋谷区',
        'price': '30000',
        'date': '2026-03-15',
      }));

      expect(find.text('テスト案件'), findsOneWidget);
    });

    testWidgets('displays location', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '千葉県千葉市',
        'price': '25000',
        'date': '2026-04-01',
      }));

      expect(find.text('千葉県千葉市'), findsWidgets);
    });

    testWidgets('displays price with yen symbol', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都',
        'price': '50000',
        'date': '2026-03-20',
      }));

      expect(find.text('¥50000'), findsOneWidget);
    });

    testWidgets('displays date', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都',
        'price': '30000',
        'date': '2026-03-15',
      }));

      expect(find.text('2026-03-15'), findsWidgets);
    });

    testWidgets('shows default description when empty', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都',
        'price': '30000',
        'date': '2026-03-15',
        'description': '',
      }));

      expect(find.textContaining('現場作業の補助'), findsOneWidget);
    });

    testWidgets('shows custom description when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget({
        'title': 'テスト案件',
        'location': '東京都',
        'price': '30000',
        'date': '2026-03-15',
        'description': 'カスタム仕事内容です',
      }));

      expect(find.text('カスタム仕事内容です'), findsOneWidget);
    });

    testWidgets('displays default values when data is missing', (tester) async {
      await tester.pumpWidget(buildTestWidget({}));

      expect(find.text('タイトルなし'), findsOneWidget);
      expect(find.text('¥0'), findsOneWidget);
    });
  });
}
