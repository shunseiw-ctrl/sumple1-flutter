import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sumple1/core/services/auth_service.dart';
import 'package:sumple1/core/services/line_auth_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/core/constants/app_colors.dart';

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

  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInAnonymously();
      Logger.info('Guest sign in successful', tag: 'GuestHomePage');

      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'ゲストとしてログインしました');
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

  void _goToEmailLogin() {
    Logger.info('Navigate to email login', tag: 'GuestHomePage');
    ErrorHandler.showInfo(context, 'メールログイン画面は準備中です');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

                const Text(
                  'ALBAWORK',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '建設業界の仕事マッチングアプリ',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInAsGuest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ruri,
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

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _goToEmailLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ruri,
                      side: BorderSide(color: AppColors.ruri, width: 2),
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
                      backgroundColor: AppColors.lineGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    TextButton(
                      onPressed: () {
                        ErrorHandler.showInfo(context, '利用規約は準備中です');
                      },
                      child: Text(
                        '利用規約',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ErrorHandler.showInfo(context, 'プライバシーポリシーは準備中です');
                      },
                      child: Text(
                        'プライバシーポリシー',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
