import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/main.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/l10n/app_localizations.dart';

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

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      image: 'assets/images/onboarding_search.png',
      title: '理想の現場を見つけよう',
      description: '建設業界の豊富な案件から\nあなたにぴったりの仕事が見つかります',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_earn.png',
      title: 'すぐに稼げる',
      description: '応募から就業までスムーズ\n日払い・週払いにも対応',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_safety.png',
      title: '安心のサポート体制',
      description: '本人確認済みの企業のみ掲載\nトラブル時もサポートします',
    ),
  ];

  bool get _canComplete => _termsAccepted && _privacyAccepted;

  Future<void> _completeOnboarding() async {
    // 最終ページの場合、同意チェックが必要
    if (_currentPage == _pages.length - 1 && !_canComplete) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    // 同意日時を保存
    final now = DateTime.now().toIso8601String();
    await prefs.setString('terms_accepted_at', now);
    await prefs.setString('privacy_accepted_at', now);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
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
      label: '$label${value ? "、同意済み" : ""}',
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.ruri,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.ruri,
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.base, top: AppSpacing.sm),
                child: Semantics(
                  button: true,
                  label: 'オンボーディングをスキップ',
                  enabled: !(_currentPage == _pages.length - 1 && !_canComplete),
                  child: TextButton(
                    onPressed: (_currentPage == _pages.length - 1 && !_canComplete)
                        ? null
                        : _completeOnboarding,
                    child: Text(
                      AppLocalizations.of(context)!.skip,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: (_currentPage == _pages.length - 1 && !_canComplete)
                            ? AppColors.divider
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingPageContent(data: _pages[index]);
                },
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
                    label: 'ページ${_currentPage + 1} / ${_pages.length}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? AppColors.ruri
                                : AppColors.divider,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage == _pages.length - 1) ...[
                    const SizedBox(height: AppSpacing.base),
                    _buildConsentCheckbox(
                      value: _termsAccepted,
                      label: AppLocalizations.of(context)!.agreeToTerms,
                      onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                      onTap: () => Navigator.pushNamed(context, '/legal', arguments: 'terms'),
                    ),
                    _buildConsentCheckbox(
                      value: _privacyAccepted,
                      label: AppLocalizations.of(context)!.agreeToPrivacy,
                      onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                      onTap: () => Navigator.pushNamed(context, '/legal', arguments: 'privacy'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    button: true,
                    label: _currentPage == _pages.length - 1 ? 'アプリを始める' : '次のページへ進む',
                    enabled: !(_currentPage == _pages.length - 1 && !_canComplete),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: (_currentPage == _pages.length - 1 && !_canComplete)
                              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                              : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ruri.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (_currentPage == _pages.length - 1 && !_canComplete)
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
                            _currentPage == _pages.length - 1 ? AppLocalizations.of(context)!.getStarted : AppLocalizations.of(context)!.next,
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

  const _OnboardingPageContent({required this.data});

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
                  color: AppColors.ruriSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
                ),
                child: Center(
                  child: Image.asset(
                    data.image,
                    fit: BoxFit.contain,
                    height: screenHeight * 0.35,
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
              color: AppColors.textSecondary,
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
  final String title;
  final String description;

  const _OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
