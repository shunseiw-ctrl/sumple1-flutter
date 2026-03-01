import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';

void main() {
  group('ErrorRetryWidget', () {
    testWidgets('デフォルトでエラーメッセージと再試行ボタンを表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              title: 'テストエラー',
              message: 'エラーの詳細',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('テストエラー'), findsOneWidget);
      expect(find.text('エラーの詳細'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('再試行ボタンのタップでコールバックが呼ばれる', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              title: 'エラー',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('network factoryでネットワークエラー表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget.network(onRetry: () {}),
          ),
        ),
      );

      expect(find.text('ネットワークエラー'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('timeout factoryでタイムアウト表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget.timeout(onRetry: () {}),
          ),
        ),
      );

      expect(find.text('タイムアウト'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off_rounded), findsOneWidget);
    });

    testWidgets('general factoryでエラー表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget.general(onRetry: () {}),
          ),
        ),
      );

      expect(find.text('エラーが発生しました'), findsOneWidget);
    });

    testWidgets('empty factoryで検索結果なし表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget.empty(onRetry: () {}),
          ),
        ),
      );

      expect(find.text('データが見つかりません'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('compact modeでサイズが小さい', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(
              title: 'エラー',
              onRetry: () {},
              isCompact: true,
            ),
          ),
        ),
      );

      // compact modeでもタイトルと再試行ボタンは表示される
      expect(find.text('エラー'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });
  });
}
