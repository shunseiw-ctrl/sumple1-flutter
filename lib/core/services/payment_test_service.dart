import 'package:sumple1/core/services/payment_service.dart';
import 'package:sumple1/data/models/payment_test_result.dart';

class PaymentTestService {
  final PaymentService _paymentService;

  PaymentTestService({PaymentService? paymentService})
      : _paymentService = paymentService ?? PaymentService();

  Future<PaymentTestResult> runTestFlow({
    required String applicationId,
    int testAmount = 1000,
  }) async {
    final steps = <PaymentTestStep>[];

    // Step 1: Connect Account確認
    try {
      final status = await _paymentService.getAccountStatus();
      final chargesEnabled = status['chargesEnabled'] ?? false;
      steps.add(PaymentTestStep(
        'アカウント確認',
        true,
        'chargesEnabled: $chargesEnabled',
      ));
    } catch (e) {
      steps.add(PaymentTestStep('アカウント確認', false, e.toString()));
    }

    // Step 2: PaymentIntent作成
    try {
      final result = await _paymentService.createPaymentIntent(
        applicationId: applicationId,
        amount: testAmount,
      );
      final paymentId = result['paymentId'] ?? 'unknown';
      steps.add(PaymentTestStep(
        '決済Intent作成',
        true,
        'paymentId: $paymentId',
      ));
    } catch (e) {
      steps.add(PaymentTestStep('決済Intent作成', false, e.toString()));
    }

    return PaymentTestResult(steps: steps);
  }
}
