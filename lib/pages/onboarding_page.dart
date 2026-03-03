import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/pages/legal_page.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/presentation/widgets/animated_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('onboarding');
  }

  List<_OnboardingData> _buildPages(AppLocalizations l10n) {
    return [
      _OnboardingData(
        image: 'assets/images/onboarding_search.png',
        fallbackIcon: Icons.search,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
      ),
      _OnboardingData(
        image: 'assets/images/onboarding_earn.png',
        fallbackIcon: Icons.payments,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
      ),
      _OnboardingData(
        image: 'assets/images/onboarding_safety.png',
        fallbackIcon: Icons.verified_user,
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
      ),
    ];
  }

  bool get _canComplete => _termsAccepted && _privacyAccepted;

  Future<void> _completeOnboarding() async {
    final pages = _buildPages(AppLocalizations.of(context)!);
    if (_currentPage == pages.length - 1 && !_canComplete) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    final now = DateTime.now().toIso8601String();
    await prefs.setString('terms_accepted_at', now);
    await prefs.setString('privacy_accepted_at', now);

    if (!mounted) return;
    context.go(RoutePaths.home);
  }

  void _nextPage() {
    final pages = _buildPages(AppLocalizations.of(context)!);
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Widget _buildConsentCheckbox({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onTap,
  }) {
    return Semantics(
      toggled: value,
      label: '$label${value ? context.l10n.onboarding_agreed : ""}',
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: context.appColors.primary,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.appColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _buildPages(l10n);

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.base, top: AppSpacing.sm),
                child: Semantics(
                  button: true,
                  label: context.l10n.onboarding_skip,
                  enabled: !(_currentPage == pages.length - 1 && !_canComplete),
                  child: TextButton(
                    onPressed: (_currentPage == pages.length - 1 && !_canComplete)
                        ? null
                        : _completeOnboarding,
                    child: Text(
                      l10n.skip,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: (_currentPage == pages.length - 1 && !_canComplete)
                            ? context.appColors.divider
                            : context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_currentPage == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 40,
                    errorBuilder: (_, __, ___) => Text(
                      'ALBAWORK',
                      style: AppTextStyles.headingLarge.copyWith(color: context.appColors.primary),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: PageView.builder(
                  key: const ValueKey('onboarding_pageview'),
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingPageContent(
                      key: ValueKey('onboarding_page_$index'),
                      data: pages[index],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  Semantics(
                    label: context.l10n.onboarding_pageIndicator((_currentPage + 1).toString(), pages.length.toString()),
                    child: AnimatedPageIndicator(
                      pageCount: pages.length,
                      currentPage: _currentPage,
                    ),
                  ),
                  if (_currentPage == pages.length - 1) ...[
                    const SizedBox(height: AppSpacing.base),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.appColors.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(color: context.appColors.surface.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              _buildConsentCheckbox(
                                value: _termsAccepted,
                                label: l10n.agreeToTerms,
                                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                                onTap: () => context.push(RoutePaths.legal, extra: {
                                  'title': context.l10n.onboarding_termsOfService,
                                  'htmlContent': LegalPage.termsHtml,
                                }),
                              ),
                              _buildConsentCheckbox(
                                value: _privacyAccepted,
                                label: l10n.agreeToPrivacy,
                                onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                                onTap: () => context.push(RoutePaths.legal, extra: {
                                  'title': context.l10n.onboarding_privacyPolicy,
                                  'htmlContent': LegalPage.privacyPolicyHtml,
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    button: true,
                    label: _currentPage == pages.length - 1 ? context.l10n.onboarding_getStarted : context.l10n.onboarding_nextPage,
                    enabled: !(_currentPage == pages.length - 1 && !_canComplete),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: (_currentPage == pages.length - 1 && !_canComplete)
                              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                              : context.appColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          boxShadow: [
                            BoxShadow(
                              color: context.appColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (_currentPage == pages.length - 1 && !_canComplete)
                              ? null
                              : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          child: Text(
                            _currentPage == pages.length - 1 ? l10n.getStarted : l10n.next,
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageContent extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPageContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        children: [
          Semantics(
            excludeSemantics: true,
            child: SizedBox(
              height: screenHeight * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: context.appColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
                ),
                child: Center(
                  child: Image.asset(
                    data.image,
                    fit: BoxFit.contain,
                    height: screenHeight * 0.35,
                    errorBuilder: (_, __, ___) => Icon(
                      data.fallbackIcon,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            data.title,
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            data.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.appColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String image;
  final IconData fallbackIcon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.image,
    required this.fallbackIcon,
    required this.title,
    required this.description,
  });
}
