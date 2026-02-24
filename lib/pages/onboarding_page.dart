import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/main.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
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
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'スキップ',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
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
                  Row(
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
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ruri.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? '始める' : '次へ',
                          style: AppTextStyles.button.copyWith(color: Colors.white),
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
          SizedBox(
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
