import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/config/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('enableStripePaymentsがfalse', () {
      expect(FeatureFlags.enableStripePayments, isFalse);
    });

    test('enableEarlyPaymentがfalse', () {
      expect(FeatureFlags.enableEarlyPayment, isFalse);
    });

    test('フラグがconstである', () {
      // constであることを検証 — コンパイル時に決定される
      const stripe = FeatureFlags.enableStripePayments;
      const early = FeatureFlags.enableEarlyPayment;
      expect(stripe, isFalse);
      expect(early, isFalse);
    });
  });
}
