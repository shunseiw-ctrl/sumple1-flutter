import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/async_value_builder.dart';

void main() {
  group('AsyncValueBuilder', () {
    testWidgets('shows loading widget while waiting for data', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueBuilder<String>(
              stream: controller.stream,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows builder content when data arrives', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueBuilder<String>(
              stream: controller.stream,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      controller.add('Hello');
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      controller.close();
    });

    testWidgets('shows error widget on error', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueBuilder<String>(
              stream: controller.stream,
              builder: (context, data) => Text(data),
              error: (error, retry) => Text('Error: $error'),
            ),
          ),
        ),
      );

      controller.addError('test error');
      await tester.pump();

      expect(find.textContaining('Error'), findsOneWidget);

      controller.close();
    });

    testWidgets('contains AnimatedSwitcher for transitions', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueBuilder<String>(
              stream: controller.stream,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedSwitcher), findsOneWidget);

      controller.close();
    });
  });
}
