import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/services/auth_service.dart';
import 'package:sumple1/core/services/line_auth_service.dart';
import 'package:sumple1/core/services/apple_auth_service.dart';
import 'package:sumple1/core/services/google_auth_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/pages/legal_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/l10n/app_localizations.dart';

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  final _authService = AuthService();
  final _appleAuthService = AppleAuthService();
  final _googleAuthService = GoogleAuthService();
  bool _isLoading = false;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('guest_home');
    Logger.info('GuestHomePage initialized', tag: 'GuestHomePage');
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });
  }

  Future<void> _recordTermsAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('terms_accepted_at') == null) {
      final now = DateTime.now().toIso8601String();
      await prefs.setString('terms_accepted_at', now);
      await prefs.setString('privacy_accepted_at', now);
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInAnonymously();
      await _recordTermsAcceptance();
      Logger.info('Guest sign in successful', tag: 'GuestHomePage');

      if (!mounted) return;
      ErrorHandler.showSuccess(context, context.l10n.guestHome_guestLoginSuccess);
      context.go('/');
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

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      final result = await _appleAuthService.signInWithApple();
      if (result == null) {
        // ユーザーがキャンセル
        Logger.info('Apple sign in cancelled', tag: 'GuestHomePage');
        return;
      }
      await _recordTermsAcceptance();
      Logger.info('Apple sign in successful', tag: 'GuestHomePage');
      if (!mounted) return;
      ErrorHandler.showSuccess(context, context.l10n.guestHome_appleLoginSuccess);
      context.go('/');
    } catch (e) {
      Logger.error('Apple sign in failed: $e', tag: 'GuestHomePage', error: e);
      if (!mounted) return;
      // デバッグ用に具体的なエラーメッセージを表示
      ErrorHandler.showError(context, e, customMessage: 'Apple: ${e.runtimeType}: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final result = await _googleAuthService.signInWithGoogle();
      if (result == null) {
        // ユーザーがキャンセル
        Logger.info('Google sign in cancelled', tag: 'GuestHomePage');
        return;
      }
      await _recordTermsAcceptance();
      Logger.info('Google sign in successful', tag: 'GuestHomePage');
      if (!mounted) return;
      ErrorHandler.showSuccess(context, context.l10n.guestHome_googleLoginSuccess);
      context.go('/');
    } catch (e) {
      Logger.error('Google sign in failed', tag: 'GuestHomePage', error: e);
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithLine() async {
    setState(() => _isLoading = true);

    try {
      final result = await LineAuthService().startLineLogin();
      if (result == null) {
        // Web: リダイレクトフロー or キャンセル
        Logger.info('LINE sign in cancelled or redirecting', tag: 'GuestHomePage');
        return;
      }
      await _recordTermsAcceptance();
      Logger.info('LINE sign in successful', tag: 'GuestHomePage');
      if (!mounted) return;
      ErrorHandler.showSuccess(context, context.l10n.guestHome_lineLoginSuccess);
      context.go('/');
    } catch (e) {
      Logger.error('LINE sign in failed', tag: 'GuestHomePage', error: e);
      if (!mounted) return;
      ErrorHandler.showError(context, e, customMessage: context.l10n.guestHome_lineLoginFailed);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToEmailLogin() {
    Logger.info('Navigate to email login', tag: 'GuestHomePage');
    context.push(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2B5B), Color(0xFF1E50A2), Color(0xFF3A7BD5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.xxxl,
                      AppSpacing.pagePadding,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.15),
                                blurRadius: 32,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.construction_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'ALBAWORK',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.guestHome_subtitle,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            _buildFeatureCard(
                              icon: Icons.search_rounded,
                              label: context.l10n.guestHome_featureSearch,
                            ),
                            const SizedBox(width: 10),
                            _buildFeatureCard(
                              icon: Icons.flash_on_rounded,
                              label: context.l10n.guestHome_featureEarn,
                            ),
                            const SizedBox(width: 10),
                            _buildFeatureCard(
                              icon: Icons.verified_user_rounded,
                              label: context.l10n.guestHome_featurePayment,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.appColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xxl,
                        AppSpacing.xl,
                        AppSpacing.base,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                boxShadow: AppShadows.button,
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signInAsGuest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                  ),
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
                                    : Text(
                                        context.l10n.guestHome_startAsGuest,
                                        style: AppTextStyles.button.copyWith(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.lineGreen,
                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.lineGreen.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signInWithLine,
                                icon: const Icon(Icons.chat_bubble, size: 22),
                                label: Text(
                                  context.l10n.guestHome_lineLogin,
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4),
                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                icon: const Icon(Icons.g_mobiledata, size: 28),
                                label: Text(
                                  context.l10n.guestHome_googleLogin,
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Apple Sign In (iOS/macOS のみ表示)
                          if (!kIsWeb &&
                              (Theme.of(context).platform ==
                                      TargetPlatform.iOS ||
                                  Theme.of(context).platform ==
                                      TargetPlatform.macOS))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _signInWithApple,
                                  icon: const Icon(Icons.apple, size: 24),
                                  label: Text(
                                    AppLocalizations.of(context)
                                            ?.signInWithApple ??
                                        'Appleでサインイン',
                                    style: AppTextStyles.button.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.buttonRadius),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      context.push(RoutePaths.phoneAuth);
                                    },
                              icon: const Icon(Icons.phone, size: 22),
                              label: Text(
                                context.l10n.guestHome_phoneLogin,
                                style: AppTextStyles.button.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ruri,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _goToEmailLogin,
                              icon: const Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: AppColors.ruri,
                              ),
                              label: Text(
                                context.l10n.guestHome_emailLogin,
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.ruri,
                                  fontSize: 15,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.ruri,
                                side: BorderSide(
                                  color: context.appColors.border,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              context.l10n.guestHome_agreeByLogin,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: context.appColors.textHint,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: () {
                                  context.push(RoutePaths.legal, extra: {'title': context.l10n.guestHome_termsOfService, 'htmlContent': LegalPage.termsHtml});
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  context.l10n.guestHome_termsOfService,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: context.appColors.textHint,
                                    decoration: TextDecoration.underline,
                                    decorationColor: context.appColors.textHint,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '・',
                                  style: TextStyle(
                                    color: context.appColors.textHint,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.push(RoutePaths.legal, extra: {'title': context.l10n.guestHome_privacyPolicy, 'htmlContent': LegalPage.privacyPolicyHtml});
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  context.l10n.guestHome_privacyPolicy,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: context.appColors.textHint,
                                    decoration: TextDecoration.underline,
                                    decorationColor: context.appColors.textHint,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
