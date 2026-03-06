import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/services/phone_auth_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/core/utils/logger.dart';

class PhoneAuthPage extends StatefulWidget {
  final PhoneAuthService? phoneAuthService;
  final bool linkMode;

  const PhoneAuthPage({super.key, this.phoneAuthService, this.linkMode = false});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  late final PhoneAuthService _phoneAuthService;
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
    _phoneAuthService = widget.phoneAuthService ?? PhoneAuthService();
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

  /// APNsトークンを確保してreCAPTCHAフォールバックを回避
  Future<void> _ensureApnsToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        await messaging.requestPermission(alert: false, sound: false, badge: false);
      }
      // APNsトークン取得を待機（iOSのPhone認証に必要）
      await messaging.getAPNSToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      Logger.warning('APNs token fetch failed: $e', tag: 'PhoneAuth');
    }
  }

  Future<void> _sendCode() async {
    final raw = _phoneController.text.trim();
    if (!_isValidPhone(raw)) {
      ErrorHandler.showError(context, null, customMessage: context.l10n.phoneAuth_invalidPhoneNumber);
      return;
    }

    // キーボードを閉じる（SFSafariViewController表示の競合回避）
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() => _isLoading = true);
    final phoneNumber = _formatPhoneNumber(raw);

    // APNsトークンを事前取得（サイレントプッシュ検証に必要）
    await _ensureApnsToken();

    try {
      await _phoneAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        resendToken: _resendToken,
        onAutoVerified: (credential) async {
          // 自動検証（Android）
          try {
            if (widget.linkMode) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) throw Exception('Not signed in');
              await user.linkWithCredential(credential);
              if (!mounted) return;
              ErrorHandler.showSuccess(context, context.l10n.phoneLinking_success);
              Navigator.pop(context, true);
            } else {
              await _phoneAuthService.signInWithCredential(credential);
              if (!mounted) return;
              ErrorHandler.showSuccess(context, context.l10n.phoneAuth_loginSuccess);
              context.go(RoutePaths.home);
            }
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ErrorHandler.showError(context, null, customMessage: context.l10n.phoneAuth_enterSixDigitCode);
      return;
    }
    if (_verificationId == null) {
      ErrorHandler.showError(context, null, customMessage: context.l10n.phoneAuth_restartVerification);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = _phoneAuthService.createCredential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (widget.linkMode) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Not signed in');
        await user.linkWithCredential(credential);
        if (!mounted) return;
        ErrorHandler.showSuccess(context, context.l10n.phoneLinking_success);
        Navigator.pop(context, true);
      } else {
        await _phoneAuthService.signInWithCredential(credential);
        if (!mounted) return;
        ErrorHandler.showSuccess(context, context.l10n.phoneAuth_loginSuccess);
        context.go(RoutePaths.home);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(widget.linkMode
            ? context.l10n.phoneLinking_title
            : context.l10n.phoneAuth_title),
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
              color: context.appColors.primaryPale,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.phone_android, size: 36, color: context.appColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            context.l10n.phoneAuth_smsDescription,
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            context.l10n.phoneAuth_enterJapaneseNumber,
            style: AppTextStyles.bodySmall.copyWith(color: context.appColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(context.l10n.phoneAuth_phoneNumberLabel, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: context.appColors.chipUnselected,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                border: Border.all(color: context.appColors.border),
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
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: context.appColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    borderSide: BorderSide(color: context.appColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    borderSide: BorderSide(color: context.appColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    borderSide: BorderSide(color: context.appColors.primary, width: 2),
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
              backgroundColor: context.appColors.primary,
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
                    context.l10n.phoneAuth_sendCode,
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
              color: context.appColors.primaryPale,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.sms_outlined, size: 36, color: context.appColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            context.l10n.phoneAuth_enterCode,
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            context.l10n.phoneAuth_codeSentTo(_phoneController.text.trim()),
            style: AppTextStyles.bodySmall.copyWith(color: context.appColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(context.l10n.phoneAuth_verificationCodeLabel, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
              color: context.appColors.textHint,
            ),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              borderSide: BorderSide(color: context.appColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              borderSide: BorderSide(color: context.appColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              borderSide: BorderSide(color: context.appColors.primary, width: 2),
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
              backgroundColor: context.appColors.primary,
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
                    context.l10n.phoneAuth_login,
                    style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: _countdown > 0
              ? Text(
                  context.l10n.phoneAuth_resendCountdown(_countdown.toString()),
                  style: AppTextStyles.bodySmall.copyWith(color: context.appColors.textSecondary),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: Text(
                    context.l10n.phoneAuth_resendCode,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.appColors.primary,
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
              context.l10n.phoneAuth_changePhoneNumber,
              style: AppTextStyles.labelMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
