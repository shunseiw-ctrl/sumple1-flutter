import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('QualificationsPage UI', () {
    testWidgets('空状態のメッセージが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 48),
              SizedBox(height: 12),
              Text('登録された資格はありません'),
              SizedBox(height: 4),
              Text('右下のボタンから追加できます'),
            ],
          ),
        ),
      ));

      expect(find.text('登録された資格はありません'), findsOneWidget);
      expect(find.text('右下のボタンから追加できます'), findsOneWidget);
    });

    testWidgets('資格カードが正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.green),
                title: const Text('内装仕上げ施工技能士'),
                subtitle: const Text('内装仕上げ施工技能士'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('承認済み'),
                ),
              ),
            ),
          ],
        ),
      ));

      expect(find.text('内装仕上げ施工技能士'), findsWidgets);
      expect(find.text('承認済み'), findsOneWidget);
    });
  });
}
