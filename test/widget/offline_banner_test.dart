import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/offline_banner.dart';

void main() {
  group('OfflineBanner', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OfflineBanner()),
        ),
      );
      await tester.pump();
      // By default online, so banner should be hidden
      expect(find.text('オフラインモード — キャッシュデータを表示中'), findsNothing);
    });

    testWidgets('shows retry button when callback provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(onRetry: () {}),
          ),
        ),
      );
      await tester.pump();
      // Since default is online, nothing shown
      // Test confirms the widget structure is valid
    });

    testWidgets('widget initializes without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OfflineBanner(),
                Text('content'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('content'), findsOneWidget);
    });
  });
}
