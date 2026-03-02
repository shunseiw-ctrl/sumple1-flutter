import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('WorkReportsTab UI', () {
    testWidgets('空状態のメッセージが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 48),
              SizedBox(height: 12),
              Text('日報はまだありません'),
              SizedBox(height: 4),
              Text('右下のボタンから作成できます'),
            ],
          ),
        ),
      ));

      expect(find.text('日報はまだありません'), findsOneWidget);
      expect(find.text('右下のボタンから作成できます'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('日報カードが正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.description),
                title: const Text('2025-04-01'),
                subtitle: const Text('内装工事の作業を行いました'),
                trailing: const Text('8.0h'),
              ),
            ),
          ],
        ),
      ));

      expect(find.text('2025-04-01'), findsOneWidget);
      expect(find.text('内装工事の作業を行いました'), findsOneWidget);
      expect(find.text('8.0h'), findsOneWidget);
    });
  });
}
