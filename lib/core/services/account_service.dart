import 'package:cloud_functions/cloud_functions.dart';

/// アカウント削除・データエクスポートサービス
///
/// Cloud Functions を呼び出してユーザーデータの削除/エクスポートを行う。
/// DI 対応: テスト時に FirebaseFunctions インスタンスを注入可能。
class AccountService {
  final FirebaseFunctions _functions;

  AccountService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  /// アカウント削除 — 全ユーザーデータを削除し、Firebase Auth アカウントも削除
  Future<void> deleteAccount() async {
    final callable = _functions.httpsCallable('deleteUserData');
    await callable.call();
  }

  /// データエクスポート — ユーザーの全データを JSON Map で返却
  Future<Map<String, dynamic>> exportUserData() async {
    final callable = _functions.httpsCallable('exportUserData');
    final result = await callable.call();
    return Map<String, dynamic>.from(result.data as Map);
  }
}
