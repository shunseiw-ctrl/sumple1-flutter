import 'package:flutter_line_sdk/flutter_line_sdk.dart';

/// LINE SDK のラッパー（DI/テスト用）
abstract class LineSDKWrapper {
  /// LINE SDK ネイティブログイン
  Future<LineSDKLoginResult?> login();

  /// LINE SDK ログアウト
  Future<void> logout();
}

/// LINE SDK の実プロダクション実装
class LineSDKWrapperImpl implements LineSDKWrapper {
  @override
  Future<LineSDKLoginResult?> login() async {
    final result = await LineSDK.instance.login();
    return LineSDKLoginResult(
      accessToken: result.accessToken.value,
      displayName: result.userProfile?.displayName ?? '',
      userId: result.userProfile?.userId ?? '',
      pictureUrl: result.userProfile?.pictureUrl ?? '',
    );
  }

  @override
  Future<void> logout() async {
    await LineSDK.instance.logout();
  }
}

/// LINE SDK ログイン結果のデータクラス
class LineSDKLoginResult {
  final String accessToken;
  final String displayName;
  final String userId;
  final String pictureUrl;

  const LineSDKLoginResult({
    required this.accessToken,
    required this.displayName,
    required this.userId,
    required this.pictureUrl,
  });
}
