/// V1フィーチャーフラグ
/// Stripe決済はオフラインV1では無効化
class FeatureFlags {
  FeatureFlags._();

  /// Stripe決済機能を有効にする（V1: false）
  static const bool enableStripePayments = false;

  /// 即金申請機能を有効にする（V1: false）
  static const bool enableEarlyPayment = false;
}
