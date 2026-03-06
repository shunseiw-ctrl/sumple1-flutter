/// Google OAuth クライアントID定数
/// GoogleAuthService と AccountLinkingService で共有
class GoogleAuthConstants {
  GoogleAuthConstants._();

  /// GoogleService-Info.plist の CLIENT_ID（iOS OAuth クライアント）
  static const String iosClientId =
      '319960355608-svkte1q6p25mv675qqf8a0di89mi85lk.apps.googleusercontent.com';

  /// Firebase Auth の Google プロバイダー Web クライアントID
  static const String webClientId =
      '319960355608-pfuh6qe42hqtbm372ti9egv3r99bbh0k.apps.googleusercontent.com';
}
