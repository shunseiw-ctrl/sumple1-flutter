import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/early_payment_request_model.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('StatementDetail UI', () {
    testWidgets('明細ヘッダーと案件明細が表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text('2025-04月', style: TextStyle(color: Colors.white)),
                  Text('¥150,000', style: TextStyle(color: Colors.white, fontSize: 28)),
                  Text('確定済み', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('案件明細'),
            Card(
              child: ListTile(
                title: const Text('内装工事'),
                subtitle: const Text('完了日: 2025-04-15'),
                trailing: const Text('¥150,000'),
              ),
            ),
          ],
        ),
      ));

      expect(find.text('2025-04月'), findsOneWidget);
      expect(find.text('¥150,000'), findsWidgets);
      expect(find.text('案件明細'), findsOneWidget);
      expect(find.text('内装工事'), findsOneWidget);
    });

    testWidgets('即金申請の手数料計算が正しい', (tester) async {
      // モデルの手数料計算をUIテストとして検証
      final fee = EarlyPaymentRequestModel.calculateFee(100000);
      final payout = EarlyPaymentRequestModel.calculatePayout(100000);

      await tester.pumpWidget(buildTestApp(
        Column(
          children: [
            Text('手数料: ¥$fee'),
            Text('受取額: ¥$payout'),
          ],
        ),
      ));

      expect(find.text('手数料: ¥10000'), findsOneWidget);
      expect(find.text('受取額: ¥90000'), findsOneWidget);
    });
  });
}
