import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// ログレベル
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// アプリ全体のログ管理
class Logger {
  /// ログを出力
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode && (level == LogLevel.debug || level == LogLevel.info)) return;

    final prefix = tag != null ? '[$tag]' : '';
    final dataStr = data != null && data.isNotEmpty ? ' | data: $data' : '';
    final errorStr = error != null ? ' | error: $error' : '';

    final logMessage = '$prefix $message$dataStr$errorStr';

    switch (level) {
      case LogLevel.error:
        debugPrint('❌ $logMessage');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
        if (!kIsWeb) {
          try {
            FirebaseCrashlytics.instance.recordError(
              error ?? logMessage,
              stackTrace,
              reason: logMessage,
            );
          } catch (_) {
            // Crashlytics not initialized (e.g., in tests)
          }
        }
        break;
      case LogLevel.warning:
        debugPrint('⚠️  $logMessage');
        break;
      case LogLevel.info:
        debugPrint('ℹ️  $logMessage');
        break;
      case LogLevel.debug:
        debugPrint('🐛 $logMessage');
        break;
    }
  }

  /// デバッグログ
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.debug, tag: tag, data: data);
  }

  /// 情報ログ
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.info, tag: tag, data: data);
  }

  /// 警告ログ
  static void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, level: LogLevel.warning, tag: tag, data: data);
  }

  /// エラーログ
  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      message,
      level: LogLevel.error,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }
}
