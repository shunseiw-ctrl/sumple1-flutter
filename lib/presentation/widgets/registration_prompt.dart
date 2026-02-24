import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/line_auth_service.dart';
import '../../core/utils/logger.dart';

/// 登録を促すモーダルダイアログウィジェット
class RegistrationPromptModal {
  /// 登録を促すダイアログを表示
  static Future<void> show(
    BuildContext context, {
    String featureName = 'この機能を使う',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // アイコン
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.ruriPale,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: AppColors.ruri,
                  ),
                ),

                const SizedBox(height: 24),

                // タイトル
                Text(
                  '$featureName には登録が必要です',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // 説明文
                Text(
                  'LINEまたはメールアドレスで登録して、\nすべての機能をご利用ください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // LINEログインボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleLineLogin(context);
                    },
                    icon: const Icon(Icons.chat_bubble, size: 20),
                    label: const Text(
                      'LINEで登録',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lineGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // メール登録ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleEmailLogin(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ruri,
                      side: const BorderSide(color: AppColors.ruri, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'メールアドレスで登録',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 後でボタン
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '後で',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// LINE ログインを処理
  static void _handleLineLogin(BuildContext context) {
    Logger.info('LINE login started from registration prompt', tag: 'RegistrationPromptModal');
    try {
      LineAuthService().startLineLogin();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LINEログインページへ移動します'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Logger.error('LINE login failed', tag: 'RegistrationPromptModal', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// メール登録を処理
  static void _handleEmailLogin(BuildContext context) {
    Logger.info('Email registration started from registration prompt', tag: 'RegistrationPromptModal');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('メール登録ページへ移動します'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to admin_login_page for email registration
    // Navigator.pushNamed(context, '/admin_login');
  }
}
