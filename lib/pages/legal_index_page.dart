import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
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
        title: Text(
          context.l10n.legalIndex_title,
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
              ProfileSectionHeader(title: context.l10n.legalIndex_legalDocuments),
              ProfileMenuGroup(
                children: [
                  ProfileMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: context.appColors.primary,
                    title: context.l10n.legalIndex_privacyPolicy,
                    onTap: () => _navigateToLegal(
                      context.l10n.legalIndex_privacyPolicy,
                      LegalPage.privacyPolicyHtml,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.description_outlined,
                    iconColor: context.appColors.primary,
                    title: context.l10n.legalIndex_termsOfService,
                    isLast: true,
                    onTap: () => _navigateToLegal(
                      context.l10n.legalIndex_termsOfService,
                      LegalPage.termsHtml,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ProfileSectionHeader(title: context.l10n.legalIndex_compliance),
              ProfileMenuGroup(
                children: [
                  ProfileMenuTile(
                    icon: Icons.health_and_safety_outlined,
                    iconColor: context.appColors.warning,
                    title: context.l10n.legalIndex_laborInsurance,
                    onTap: () => _navigateToLegal(
                      context.l10n.legalIndex_laborInsurance,
                      LegalPage.laborInsuranceHtml,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.business_outlined,
                    iconColor: context.appColors.info,
                    title: context.l10n.legalIndex_dispatchLaw,
                    onTap: () => _navigateToLegal(
                      context.l10n.legalIndex_dispatchLaw,
                      LegalPage.dispatchLawHtml,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.work_outline,
                    iconColor: context.appColors.success,
                    title: context.l10n.legalIndex_employmentSecurityLaw,
                    isLast: true,
                    onTap: () => _navigateToLegal(
                      context.l10n.legalIndex_employmentSecurityLaw,
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
