import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';

void main() {
  group('SkeletonLoader variants', () {
    testWidgets('SkeletonMessageCard renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonMessageCard()),
        ),
      );

      expect(find.byType(SkeletonMessageCard), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('SkeletonNotificationCard renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonNotificationCard()),
        ),
      );

      expect(find.byType(SkeletonNotificationCard), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('SkeletonWorkCard renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonWorkCard()),
        ),
      );

      expect(find.byType(SkeletonWorkCard), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('SkeletonSalesCard renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonSalesCard()),
        ),
      );

      expect(find.byType(SkeletonSalesCard), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('SkeletonList uses custom itemBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonList(
              itemBuilder: (_) => const SkeletonMessageCard(),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonMessageCard), findsWidgets);
      expect(find.byType(SkeletonJobCard), findsNothing);
    });

    testWidgets('SkeletonList defaults to SkeletonJobCard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonList()),
        ),
      );

      expect(find.byType(SkeletonJobCard), findsWidgets);
    });
  });
}
