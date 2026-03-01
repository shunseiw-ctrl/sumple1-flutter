import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

/// アプリケーション環境
enum AppEnvironment { staging, production }

/// 環境設定マネージャー
///
/// ビルド時に `--dart-define=ENV=staging` で環境を切り替え可能。
/// デフォルトは production。
class AppConfig {
  static const _envString = String.fromEnvironment('ENV', defaultValue: 'production');

  static AppEnvironment get environment {
    switch (_envString) {
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.production;
    }
  }

  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isProduction => environment == AppEnvironment.production;

  /// 現在の環境に対応する FirebaseOptions を返す。
  ///
  /// staging 環境用の firebase_options_staging.dart は
  /// `flutterfire configure -p alba-work-staging -o lib/firebase_options_staging.dart`
  /// で生成する必要がある。
  ///
  /// 現時点では staging プロジェクト未作成のため production と同じ Options を返す。
  /// staging プロジェクト作成後にコメントを解除して切り替えること。
  static FirebaseOptions get firebaseOptions {
    // TODO: staging プロジェクト作成後に下記を有効化
    // if (isStaging) {
    //   return StagingFirebaseOptions.currentPlatform;
    // }
    return DefaultFirebaseOptions.currentPlatform;
  }

  /// 環境名（ログ表示用）
  static String get environmentName => _envString;
}
