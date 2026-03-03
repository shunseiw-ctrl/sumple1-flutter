import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/async_value_builder.dart';

void main() {
  group('FutureRetryBuilder', () {
    testWidgets('shows data on success', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FutureRetryBuilder<String>(
              futureFactory: () => Future.value('Hello'),
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('shows loading initially', (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FutureRetryBuilder<String>(
              futureFactory: () => completer.future,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete('done');
      await tester.pumpAndSettle();
      expect(find.text('done'), findsOneWidget);
    });
  });
}
