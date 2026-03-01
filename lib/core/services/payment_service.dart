import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  static final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  /// Stripe Expressアカウント作成（オンボーディングURL取得）
  static Future<Map<String, dynamic>> createConnectAccount({String? email}) async {
    final callable = _functions.httpsCallable('createConnectAccount');
    final result = await callable.call<Map<String, dynamic>>({
      'email': email ?? '',
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// オンボーディングURL再生成
  static Future<String> createAccountLink() async {
    final callable = _functions.httpsCallable('createAccountLink');
    final result = await callable.call<Map<String, dynamic>>({});
    return result.data['url'] as String;
  }

  /// アカウント状態確認
  static Future<Map<String, dynamic>> getAccountStatus() async {
    final callable = _functions.httpsCallable('getAccountStatus');
    final result = await callable.call<Map<String, dynamic>>({});
    return Map<String, dynamic>.from(result.data);
  }

  /// 決済作成
  static Future<Map<String, dynamic>> createPaymentIntent({
    required String applicationId,
    required int amount,
  }) async {
    final callable = _functions.httpsCallable('createPaymentIntent');
    final result = await callable.call<Map<String, dynamic>>({
      'applicationId': applicationId,
      'amount': amount,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Expressダッシュボードリンク取得
  static Future<String> getExpressDashboardLink() async {
    final callable = _functions.httpsCallable('getExpressDashboardLink');
    final result = await callable.call<Map<String, dynamic>>({});
    return result.data['url'] as String;
  }
}
