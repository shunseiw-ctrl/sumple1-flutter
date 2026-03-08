import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'logger.dart';

/// アプリ全体のエラーハンドリング
class ErrorHandler {
  /// エラーメッセージをSnackBarで表示
  static void showError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    Duration duration = const Duration(seconds: 3),
  }) {
    final message = customMessage ?? _getErrorMessage(error);

    Logger.error(
      'Showing error to user',
      tag: 'ErrorHandler',
      error: error,
      data: {'message': message},
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 成功メッセージをSnackBarで表示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    Logger.info('Showing success message', tag: 'ErrorHandler', data: {'message': message});

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 情報メッセージをSnackBarで表示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// エラーからユーザー向けメッセージを生成
  static String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    } else if (error is String) {
      return error;
    } else {
      return 'エラーが発生しました。しばらく経ってからお試しください';
    }
  }

  /// Firebase Authentication エラーメッセージ
  static String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'operation-not-allowed':
        return 'この操作は許可されていません';
      case 'weak-password':
        return 'パスワードが弱すぎます（6文字以上を推奨）';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく待ってから再試行してください';
      default:
        Logger.warning('Unhandled auth error code: ${e.code}', tag: 'ErrorHandler');
        return '認証エラーが発生しました。しばらく経ってからお試しください';
    }
  }

  /// Firestore エラーメッセージ
  static String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return '権限がありません';
      case 'not-found':
        return 'データが見つかりません';
      case 'already-exists':
        return 'データが既に存在します';
      case 'cancelled':
        return '操作がキャンセルされました';
      case 'data-loss':
        return 'データが失われました';
      case 'deadline-exceeded':
        return 'タイムアウトしました';
      case 'failed-precondition':
        return '前提条件が満たされていません';
      case 'internal':
        return '内部エラーが発生しました';
      case 'invalid-argument':
        return '無効な引数です';
      case 'resource-exhausted':
        return 'リソースが不足しています';
      case 'unauthenticated':
        return '認証されていません';
      case 'unavailable':
        return 'サービスが利用できません';
      case 'unimplemented':
        return 'この機能は実装されていません';
      case 'unknown':
        return '不明なエラーが発生しました';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました';
      default:
        Logger.warning('Unhandled Firebase error code: ${e.code}', tag: 'ErrorHandler');
        return 'エラーが発生しました。しばらく経ってからお試しください';
    }
  }

  /// AppResult を処理してSnackBar表示
  static void handleResult<T>(
    BuildContext context,
    dynamic result, {
    void Function(T data)? onSuccess,
    String? successMessage,
  }) {
    // Import-free: duck-type check for AppResult-like objects
    if (result.isSuccess == true) {
      if (onSuccess != null && result.data != null) {
        onSuccess(result.data as T);
      }
      if (successMessage != null) {
        showSuccess(context, successMessage);
      }
    } else {
      final msg = result.errorMessage?.toString() ?? 'エラーが発生しました';
      showError(context, null, customMessage: msg);
    }
  }

  /// AppResult のエラーのみSnackBar表示
  static void showResultError(BuildContext context, dynamic result) {
    if (result.isSuccess == true) return;
    final msg = result.errorMessage?.toString() ?? 'エラーが発生しました';
    showError(context, null, customMessage: msg);
  }

  /// 確認ダイアログを表示
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'はい',
    String cancelText = 'いいえ',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: isDangerous
                  ? TextButton.styleFrom(foregroundColor: Colors.red)
                  : null,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
