import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
        debugPrint('ERROR $logMessage');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
        // Crashlytics に送信（Web以外）
        if (!kIsWeb) {
          _sendToCrashlytics(message, error, stackTrace, tag);
        }
        break;
      case LogLevel.warning:
        debugPrint('WARN  $logMessage');
        break;
      case LogLevel.info:
        debugPrint('INFO  $logMessage');
        break;
      case LogLevel.debug:
        debugPrint('DEBUG $logMessage');
        break;
    }
  }

  /// Crashlytics にエラーを送信
  static void _sendToCrashlytics(
    String message,
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ) {
    try {
      if (tag != null) {
        FirebaseCrashlytics.instance.setCustomKey('tag', tag);
      }
      FirebaseCrashlytics.instance.log(message);
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: false,
        );
      }
    } catch (_) {
      // Crashlytics が初期化されていない場合は無視
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
