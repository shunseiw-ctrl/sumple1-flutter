import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';

void main() {
  group('StatusBadge constructor', () {
    testWidgets('renders label and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'テスト',
              color: Colors.blue,
              icon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.text('テスト'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders without icon when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'ラベルのみ',
              color: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('ラベルのみ'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('StatusBadge.fromStatus', () {
    testWidgets('applied shows 応募中', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromStatus('applied'),
          ),
        ),
      );

      expect(find.text('応募中'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('assigned shows 着工前', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromStatus('assigned'),
          ),
        ),
      );

      expect(find.text('着工前'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_turned_in), findsOneWidget);
    });

    testWidgets('in_progress shows 着工中', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromStatus('in_progress'),
          ),
        ),
      );

      expect(find.text('着工中'), findsOneWidget);
      expect(find.byIcon(Icons.engineering), findsOneWidget);
    });

    testWidgets('completed shows 施工完了', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromStatus('completed'),
          ),
        ),
      );

      expect(find.text('施工完了'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('inspection shows 検収中', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromStatus('inspection'),
          ),
        ),
      );

      expect(find.text('検収中'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('fixing shows 是正中', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromStatus('fixing'),
          ),
        ),
      );

      expect(find.text('是正中'), findsOneWidget);
      expect(find.byIcon(Icons.build), findsOneWidget);
    });

    testWidgets('done shows 完了', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromStatus('done'),
          ),
        ),
      );

      expect(find.text('完了'), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('unknown status shows the key as label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.fromStatus('custom_status'),
          ),
        ),
      );

      expect(find.text('custom_status'), findsOneWidget);
    });
  });
}
