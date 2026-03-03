import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/payment_test_result.dart';

void main() {
  group('PaymentTestResult', () {
    test('creates with empty steps', () {
      final result = PaymentTestResult(steps: []);
      expect(result.steps, isEmpty);
      expect(result.allPassed, true);
      expect(result.testedAt, isNotNull);
    });

    test('addStep creates new instance', () {
      final original = PaymentTestResult(steps: []);
      final updated = original.addStep(
        const PaymentTestStep('Test', true, 'detail'),
      );
      expect(original.steps.length, 0);
      expect(updated.steps.length, 1);
    });

    test('PaymentTestStep toString format', () {
      const step = PaymentTestStep('アカウント確認', true, 'OK');
      expect(step.toString(), 'アカウント確認: OK - OK');
    });

    test('PaymentTestStep failed toString', () {
      const step = PaymentTestStep('決済', false, 'timeout');
      expect(step.toString(), '決済: FAIL - timeout');
    });
  });
}
