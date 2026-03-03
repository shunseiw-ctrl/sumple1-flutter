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

    testWidgets('passes through child widget', (tester) async {
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

    testWidgets('does not interfere with widget tree', (tester) async {
      await tester.pumpWidget(
        const AppErrorBoundary(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Line 1'),
                  Text('Line 2'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
    });
  });
}
