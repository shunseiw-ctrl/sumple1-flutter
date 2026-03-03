import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';

import '../../core/constants/app_colors.dart';
import '../../core/extensions/build_context_extensions.dart';
import '../../core/services/line_auth_service.dart';
import '../../core/utils/logger.dart';

/// 登録を促すモーダルダイアログウィジェット
class RegistrationPromptModal {
  /// 登録を促すダイアログを表示
  static Future<void> show(
    BuildContext context, {
    String? featureName,
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
                    color: context.appColors.primaryPale,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: context.appColors.primary,
                  ),
                ),

                const SizedBox(height: 24),

                // タイトル
                Text(
                  context.l10n.registrationPrompt_title(featureName ?? context.l10n.registrationPrompt_defaultFeature),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // 説明文
                Text(
                  context.l10n.registrationPrompt_description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appColors.textSecondary,
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
                    label: Text(
                      context.l10n.registrationPrompt_lineLogin,
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
                      foregroundColor: context.appColors.primary,
                      side: BorderSide(color: context.appColors.primary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.registrationPrompt_emailLogin,
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
                      context.l10n.registrationPrompt_later,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textSecondary,
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
        SnackBar(
          content: Text(context.l10n.registrationPrompt_lineRedirect),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Logger.error('LINE login failed', tag: 'RegistrationPromptModal', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.registrationPrompt_error(e.toString())),
          backgroundColor: context.appColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// メール登録を処理
  static void _handleEmailLogin(BuildContext context) {
    Logger.info('Email registration started from registration prompt', tag: 'RegistrationPromptModal');
    context.push(RoutePaths.login);
  }
}
