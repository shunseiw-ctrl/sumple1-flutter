import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/payment_test_result.dart';

void main() {
  group('PaymentTestService', () {
    test('PaymentTestResult tracks steps', () {
      var result = PaymentTestResult(steps: []);
      result = result.addStep(
        const PaymentTestStep('アカウント確認', true, 'OK'),
      );
      result = result.addStep(
        const PaymentTestStep('決済Intent作成', false, 'Error'),
      );

      expect(result.steps.length, 2);
      expect(result.passedCount, 1);
      expect(result.failedCount, 1);
      expect(result.allPassed, false);
    });

    test('PaymentTestResult allPassed when all steps succeed', () {
      final result = PaymentTestResult(steps: [
        const PaymentTestStep('Step 1', true, 'OK'),
        const PaymentTestStep('Step 2', true, 'OK'),
      ]);

      expect(result.allPassed, true);
      expect(result.passedCount, 2);
      expect(result.failedCount, 0);
    });
  });
}
