import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/force_update_dialog.dart';

void main() {
  group('ForceUpdateDialog', () {
    testWidgets('isForced=trueでは「あとで」ボタン非表示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ForceUpdateDialog(
              isForced: true,
              storeUrl: 'https://example.com',
            ),
          ),
        ),
      );

      expect(find.text('あとで'), findsNothing);
      expect(find.text('アップデート'), findsOneWidget);
      expect(find.text('アップデートが必要です'), findsOneWidget);
    });

    testWidgets('isForced=falseでは「あとで」ボタン表示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ForceUpdateDialog(
              isForced: false,
              storeUrl: 'https://example.com',
            ),
          ),
        ),
      );

      expect(find.text('あとで'), findsOneWidget);
      expect(find.text('アップデート'), findsOneWidget);
      expect(find.text('新しいバージョンがあります'), findsOneWidget);
    });
  });
}
