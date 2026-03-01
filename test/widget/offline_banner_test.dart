import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/offline_banner.dart';

void main() {
  group('OfflineBanner', () {
    testWidgets('オフラインメッセージを表示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(),
          ),
        ),
      );

      expect(find.text('インターネットに接続されていません'), findsOneWidget);
    });

    testWidgets('wifi_offアイコンを表示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('onRetryがnullの場合再試行ボタンを非表示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(),
          ),
        ),
      );

      expect(find.text('再試行'), findsNothing);
    });

    testWidgets('onRetry指定で再試行ボタンを表示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(onRetry: () {}),
          ),
        ),
      );

      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('再試行ボタンのタップでコールバックが呼ばれる', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(onRetry: () => retried = true),
          ),
        ),
      );

      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });
  });
}
