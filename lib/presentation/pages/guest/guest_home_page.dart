import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sumple1/core/services/auth_service.dart';
import 'package:sumple1/core/services/line_auth_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/core/utils/logger.dart';

/// 未登録ユーザー（ゲスト）用のホーム画面
class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Logger.info('GuestHomePage initialized', tag: 'GuestHomePage');
  }

  /// 匿名ログインして一般ユーザーとして利用開始
  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInAnonymously();
      Logger.info('Guest sign in successful', tag: 'GuestHomePage');

      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'ゲストとしてログインしました');
      // 認証状態が変わるとmain.dartで自動的に画面遷移される
    } catch (e) {
      Logger.error('Guest sign in failed', tag: 'GuestHomePage', error: e);
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// メールアドレスログイン画面へ遷移
  void _goToEmailLogin() {
    Logger.info('Navigate to email login', tag: 'GuestHomePage');
    // TODO: メールログイン画面を実装したら遷移
    ErrorHandler.showInfo(context, 'メールログイン画面は準備中です');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アプリロゴ・アイコン
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.construction,
                    size: 64,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // アプリ名
                const Text(
                  'ALBAWORK',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                // キャッチコピー
                const Text(
                  '建設業界の仕事マッチングアプリ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // ゲストとして始めるボタン
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInAsGuest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ゲストとして始める',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // メールアドレスでログインボタン
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _goToEmailLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'メールアドレスでログイン',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      LineAuthService().startLineLogin();
                    },
                    icon: const Icon(Icons.chat_bubble, size: 24),
                    label: const Text(
                      'LINEでログイン',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06C755),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 利用規約・プライバシーポリシー
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: 利用規約画面へ遷移
                        ErrorHandler.showInfo(context, '利用規約は準備中です');
                      },
                      child: const Text(
                        '利用規約',
                        style: TextStyle(
                          color: Colors.black54,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: プライバシーポリシー画面へ遷移
                        ErrorHandler.showInfo(context, 'プライバシーポリシーは準備中です');
                      },
                      child: const Text(
                        'プライバシーポリシー',
                        style: TextStyle(
                          color: Colors.black54,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
