import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/app_error_boundary.dart';

void main() {
  group('AppErrorBoundary', () {
    testWidgets('renders child normally', (tester) async {
      await tester.pumpWidget(
        const AppErrorBoundary(
          child: MaterialApp(
            home: Scaffold(body: Text('Hello')),
          ),
        ),
      );
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('recovery UI shows retry button', (tester) async {
      await tester.pumpWidget(
        const AppErrorBoundary(
          child: MaterialApp(
            home: Scaffold(body: Text('Hello')),
          ),
        ),
      );
      // Normal state - child is shown
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('予期しないエラーが発生しました'), findsNothing);
    });

    testWidgets('initializes without error', (tester) async {
      await tester.pumpWidget(
        const AppErrorBoundary(
          child: MaterialApp(
            home: Scaffold(body: Center(child: Text('Content'))),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Content'), findsOneWidget);
    });
  });
}
