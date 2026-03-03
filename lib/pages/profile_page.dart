import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/line_auth_service.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/providers/theme_mode_provider.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';
import 'package:sumple1/core/services/analytics_service.dart';

import 'profile/profile_widgets.dart';
import 'profile/email_auth_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isAnonymous(User? user) => user == null || user.isAnonymous;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('profile');
  }

  void _openEmailAuthDialog() {
    showEmailAuthDialog(
      context: context,
      onAuthStateChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnon = _isAnonymous(user);

    final displayName = isAnon
        ? context.l10n.profile_guest
        : (user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email?.trim().isNotEmpty == true ? user!.email!.trim() : context.l10n.profile_loggedInUser));

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.pagePadding, AppSpacing.pagePadding, 24),
        children: [
          StaggeredFadeSlide(
            index: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: context.appColors.heroGradient,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ProfileHeaderCard(
                  displayName: displayName,
                  subtitle: isAnon ? context.l10n.profile_loginPromptSubtitle : context.l10n.profile_loggedIn,
                  isLoggedIn: !isAnon,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (isAnon) ...[
            StaggeredFadeSlide(
              index: 1,
              child: InfoBanner(
                title: context.l10n.profile_loginRequired,
                message: context.l10n.profile_loginRequiredMessage,
                buttonText: context.l10n.profile_loginButton,
                onPressed: _openEmailAuthDialog,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lineGreen.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Semantics(
                button: true,
                label: context.l10n.profile_lineLoginSemanticsLabel,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      LineAuthService().startLineLogin();
                    },
                    icon: const Icon(Icons.chat_bubble, size: 20),
                    label: Text(
                      context.l10n.profile_lineLoginButton,
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lineGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          StaggeredFadeSlide(
            index: isAnon ? 3 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileSectionHeader(title: context.l10n.profile_sectionAccount),
                ProfileMenuGroup(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.settings_outlined,
                      iconColor: context.appColors.primary,
                      title: context.l10n.profile_accountSettings,
                      onTap: () {
                        context.push(RoutePaths.accountSettings);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.badge_outlined,
                      iconColor: context.appColors.info,
                      title: context.l10n.profile_yourProfile,
                      onTap: () {
                        context.push(RoutePaths.myProfile);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.verified_user_outlined,
                      iconColor: context.appColors.success,
                      title: context.l10n.profile_identityVerification,
                      subtitle: context.l10n.profile_identityVerificationSubtitle,
                      onTap: () {
                        context.push(RoutePaths.identityVerification);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.workspace_premium,
                      iconColor: Colors.teal,
                      title: context.l10n.profile_qualifications,
                      subtitle: context.l10n.profile_qualificationsSubtitle,
                      onTap: () {
                        context.push(RoutePaths.qualifications);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.account_balance_outlined,
                      iconColor: const Color(0xFF635BFF),
                      title: context.l10n.profile_stripeAccount,
                      subtitle: context.l10n.profile_stripeAccountSubtitle,
                      onTap: () {
                        context.push(RoutePaths.stripeOnboarding, extra: {
                          'email': user?.email,
                        });
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.card_giftcard_outlined,
                      iconColor: context.appColors.warning,
                      title: context.l10n.profile_inviteFriends,
                      subtitle: context.l10n.profile_inviteFriendsSubtitle,
                      onTap: () {
                        context.push(RoutePaths.referral);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.favorite_outlined,
                      iconColor: Colors.red,
                      title: context.l10n.profile_favoriteJobs,
                      subtitle: context.l10n.profile_favoriteJobsSubtitle,
                      isLast: true,
                      onTap: () {
                        context.push(RoutePaths.favorites);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          StaggeredFadeSlide(
            index: isAnon ? 4 : 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileSectionHeader(title: context.l10n.profile_sectionSupport),
                ProfileMenuGroup(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.help_outline,
                      iconColor: context.appColors.warning,
                      title: context.l10n.profile_faq,
                      onTap: () {
                        context.push(RoutePaths.faq);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.mail_outline,
                      iconColor: context.appColors.primary,
                      title: context.l10n.profile_contact,
                      isLast: true,
                      onTap: () {
                        context.push(RoutePaths.contact);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          StaggeredFadeSlide(
            index: isAnon ? 5 : 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileSectionHeader(title: context.l10n.profile_sectionOther),
                ProfileMenuGroup(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final currentMode = ref.watch(themeModeProvider);
                        String subtitle;
                        switch (currentMode) {
                          case ThemeMode.light:
                            subtitle = context.l10n.profile_darkModeLight;
                            break;
                          case ThemeMode.dark:
                            subtitle = context.l10n.profile_darkModeDark;
                            break;
                          case ThemeMode.system:
                            subtitle = context.l10n.profile_darkModeSystem;
                            break;
                        }
                        return ProfileMenuTile(
                          icon: Icons.dark_mode_outlined,
                          iconColor: context.appColors.primary,
                          title: context.l10n.profile_darkMode,
                          subtitle: subtitle,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(context.l10n.profile_darkMode),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RadioListTile<ThemeMode>(
                                      title: Text(context.l10n.profile_darkModeLight),
                                      value: ThemeMode.light,
                                      groupValue: currentMode,
                                      onChanged: (v) {
                                        ref.read(themeModeProvider.notifier).setThemeMode(v!);
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                    RadioListTile<ThemeMode>(
                                      title: Text(context.l10n.profile_darkModeDark),
                                      value: ThemeMode.dark,
                                      groupValue: currentMode,
                                      onChanged: (v) {
                                        ref.read(themeModeProvider.notifier).setThemeMode(v!);
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                    RadioListTile<ThemeMode>(
                                      title: Text(context.l10n.profile_darkModeSystem),
                                      value: ThemeMode.system,
                                      groupValue: currentMode,
                                      onChanged: (v) {
                                        ref.read(themeModeProvider.notifier).setThemeMode(v!);
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.gavel_outlined,
                      iconColor: context.appColors.textSecondary,
                      title: context.l10n.profile_legalInfo,
                      subtitle: context.l10n.profile_legalInfoSubtitle,
                      isLast: true,
                      onTap: () {
                        context.push(RoutePaths.legalIndex);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          StaggeredFadeSlide(
            index: isAnon ? 6 : 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileSectionHeader(title: context.l10n.profile_sectionAdmin),
                ProfileMenuGroup(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: context.appColors.primaryDark,
                      title: context.l10n.profile_adminLogin,
                      subtitle: context.l10n.profile_adminLoginSubtitle,
                      onTap: () {
                        context.push(RoutePaths.adminLogin);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.logout,
                      iconColor: context.appColors.error,
                      title: context.l10n.profile_adminLogout,
                      subtitle: isAnon ? context.l10n.profile_notLoggedIn : context.l10n.profile_adminLogoutSubtitle,
                      isLast: true,
                      onTap: () async {
                        final auth = FirebaseAuth.instance;
                        await auth.signOut();
                        await auth.signInAnonymously();

                        if (!context.mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.profile_snackLoggedOut)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
