import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/load_more_button.dart';

void main() {
  group('LoadMoreButton', () {
    testWidgets('hasMore=true→ボタン表示', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadMoreButton(
            hasMore: true,
            isLoading: false,
            onPressed: () => pressed = true,
          ),
        ),
      ));

      expect(find.text('もっと表示'), findsOneWidget);
      await tester.tap(find.text('もっと表示'));
      expect(pressed, true);
    });

    testWidgets('isLoading=true→スピナー表示', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadMoreButton(
            hasMore: true,
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('もっと表示'), findsNothing);
    });

    testWidgets('hasMore=false→非表示', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadMoreButton(
            hasMore: false,
            isLoading: false,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('もっと表示'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
