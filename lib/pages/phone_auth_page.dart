import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/services/phone_auth_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneAuthService = PhoneAuthService();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isStep2 = false;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;

  // 60s countdown
  Timer? _timer;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('phone_auth');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// +81 形式に変換
  String _formatPhoneNumber(String raw) {
    // ハイフン・スペース除去
    String digits = raw.replaceAll(RegExp(r'[\s\-]'), '');
    // 先頭の0を除去して+81を付与
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '+81$digits';
  }

  /// バリデーション: ハイフン除去後 0除去前の桁数が10-11桁
  bool _isValidPhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits.length >= 10 && digits.length <= 11;
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          t.cancel();
        }
      });
    });
  }

  Future<void> _sendCode() async {
    final raw = _phoneController.text.trim();
    if (!_isValidPhone(raw)) {
      ErrorHandler.showError(context, null, customMessage: '有効な電話番号を入力してください（10〜11桁）');
      return;
    }

    setState(() => _isLoading = true);
    final phoneNumber = _formatPhoneNumber(raw);

    await _phoneAuthService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      resendToken: _resendToken,
      onAutoVerified: (credential) async {
        // 自動検証（Android）
        try {
          await _phoneAuthService.signInWithCredential(credential);
          if (!mounted) return;
          ErrorHandler.showSuccess(context, 'ログインしました');
          context.go(RoutePaths.home);
        } catch (e) {
          if (!mounted) return;
          ErrorHandler.showError(context, e);
        }
      },
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isStep2 = true;
          _isLoading = false;
        });
        _startCountdown();
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ErrorHandler.showError(context, e);
      },
    );
  }

  Future<void> _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ErrorHandler.showError(context, null, customMessage: '6桁のコードを入力してください');
      return;
    }
    if (_verificationId == null) {
      ErrorHandler.showError(context, null, customMessage: '認証コードの送信からやり直してください');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = _phoneAuthService.createCredential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _phoneAuthService.signInWithCredential(credential);
      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'ログインしました');
      context.go(RoutePaths.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('電話番号でログイン'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: _isStep2 ? _buildStep2() : _buildStep1(),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.ruriPale,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.phone_android, size: 36, color: AppColors.ruri),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            'SMSで認証コードを送信します',
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            '日本の電話番号を入力してください',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('電話番号', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.chipUnselected,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '+81',
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '090-1234-5678',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    borderSide: const BorderSide(color: AppColors.ruri, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ruri,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    '認証コードを送信',
                    style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.ruriPale,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.sms_outlined, size: 36, color: AppColors.ruri),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            '認証コードを入力',
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            '${_phoneController.text.trim()} に送信された\n6桁のコードを入力してください',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('認証コード', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 28,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: AppTextStyles.displayLarge.copyWith(
              fontSize: 28,
              letterSpacing: 8,
              color: AppColors.textHint,
            ),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              borderSide: const BorderSide(color: AppColors.ruri, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ruri,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'ログイン',
                    style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: _countdown > 0
              ? Text(
                  '再送信まで ${_countdown}秒',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: Text(
                    'コードを再送信',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.ruri,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isStep2 = false;
                _otpController.clear();
                _timer?.cancel();
                _countdown = 0;
              });
            },
            child: Text(
              '電話番号を変更する',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
