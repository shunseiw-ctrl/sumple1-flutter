import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/pages/profile/profile_widgets.dart';
import 'package:sumple1/pages/legal_page.dart';

class LegalIndexPage extends StatefulWidget {
  const LegalIndexPage({super.key});

  @override
  State<LegalIndexPage> createState() => _LegalIndexPageState();
}

class _LegalIndexPageState extends State<LegalIndexPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('legal_index');
  }

  void _navigateToLegal(String title, String htmlContent) {
    context.push(RoutePaths.legal, extra: {
      'title': title,
      'htmlContent': htmlContent,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '法的情報',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              24,
            ),
            children: [
              const ProfileSectionHeader(title: '法的ドキュメント'),
              ProfileMenuGroup(
                children: [
                  ProfileMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppColors.ruri,
                    title: 'プライバシーポリシー',
                    onTap: () => _navigateToLegal(
                      'プライバシーポリシー',
                      LegalPage.privacyPolicyHtml,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.ruri,
                    title: '利用規約',
                    isLast: true,
                    onTap: () => _navigateToLegal(
                      '利用規約',
                      LegalPage.termsHtml,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const ProfileSectionHeader(title: '法令遵守'),
              ProfileMenuGroup(
                children: [
                  ProfileMenuTile(
                    icon: Icons.health_and_safety_outlined,
                    iconColor: AppColors.warning,
                    title: '労災保険について',
                    onTap: () => _navigateToLegal(
                      '労災保険について',
                      LegalPage.laborInsuranceHtml,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.business_outlined,
                    iconColor: AppColors.info,
                    title: '労働者派遣法について',
                    onTap: () => _navigateToLegal(
                      '労働者派遣法について',
                      LegalPage.dispatchLawHtml,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.work_outline,
                    iconColor: AppColors.success,
                    title: '職業安定法について',
                    isLast: true,
                    onTap: () => _navigateToLegal(
                      '職業安定法について',
                      LegalPage.employmentSecurityLawHtml,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
