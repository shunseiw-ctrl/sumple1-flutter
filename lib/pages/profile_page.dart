import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'legal_page.dart';
import '../core/services/line_auth_service.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/router/route_paths.dart';
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
        ? 'ゲスト'
        : (user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email?.trim().isNotEmpty == true ? user!.email!.trim() : 'ログインユーザー'));

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.pagePadding, AppSpacing.pagePadding, 24),
        children: [
          StaggeredFadeSlide(
            index: 0,
            child: ProfileHeaderCard(
              displayName: displayName,
              subtitle: isAnon ? 'ログインすると応募・チャットが使えます' : 'ログイン済み',
              isLoggedIn: !isAnon,
            ),
          ),
          const SizedBox(height: 16),

          if (isAnon) ...[
            StaggeredFadeSlide(
              index: 1,
              child: InfoBanner(
                title: 'ログインが必要です',
                message: '応募・チャットなど一部機能を利用するにはログインが必要です。',
                buttonText: 'ログインする',
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
                label: 'LINEアカウントでログインする',
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      LineAuthService().startLineLogin();
                    },
                    icon: const Icon(Icons.chat_bubble, size: 20),
                    label: Text(
                      'LINEでログイン',
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
                const ProfileSectionHeader(title: 'アカウント'),
                ProfileMenuGroup(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.settings_outlined,
                      iconColor: AppColors.ruri,
                      title: 'アカウント設定',
                      onTap: () {
                        context.push(RoutePaths.accountSettings);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.badge_outlined,
                      iconColor: AppColors.info,
                      title: 'あなたのプロフィール',
                      onTap: () {
                        context.push(RoutePaths.myProfile);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.verified_user_outlined,
                      iconColor: AppColors.success,
                      title: '本人確認',
                      subtitle: '身分証明書と顔写真を提出',
                      onTap: () {
                        context.push(RoutePaths.identityVerification);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.workspace_premium,
                      iconColor: Colors.teal,
                      title: '資格管理',
                      subtitle: '保有資格の登録・確認',
                      onTap: () {
                        context.push(RoutePaths.qualifications);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.account_balance_outlined,
                      iconColor: const Color(0xFF635BFF),
                      title: 'Stripe口座設定',
                      subtitle: '報酬の受取口座を設定',
                      isLast: true,
                      onTap: () {
                        context.push(RoutePaths.stripeOnboarding, extra: {
                          'email': user?.email,
                        });
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
                const ProfileSectionHeader(title: 'サポート'),
                ProfileMenuGroup(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.help_outline,
                      iconColor: AppColors.warning,
                      title: 'よくある質問',
                      onTap: () {
                        context.push(RoutePaths.faq);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.mail_outline,
                      iconColor: AppColors.ruri,
                      title: 'お問い合わせ',
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
                const ProfileSectionHeader(title: 'その他'),
                ProfileMenuGroup(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.dark_mode_outlined,
                      iconColor: AppColors.ruri,
                      title: 'ダークモード',
                      subtitle: 'システム設定に従う',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('ダークモード'),
                            content: const Text(
                              'ダークモードはお使いの端末のシステム設定に連動しています。\n\n'
                              'iOS: 設定 → 画面表示と明るさ\n'
                              'Android: 設定 → ディスプレイ → ダークテーマ',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.textSecondary,
                      title: 'プライバシーポリシー',
                      onTap: () {
                        context.push(RoutePaths.legal, extra: {
                          'title': 'プライバシーポリシー',
                          'htmlContent': LegalPage.privacyPolicyHtml,
                        });
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.textSecondary,
                      title: '利用規約',
                      isLast: true,
                      onTap: () {
                        context.push(RoutePaths.legal, extra: {
                          'title': '利用規約',
                          'htmlContent': LegalPage.termsHtml,
                        });
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
                const ProfileSectionHeader(title: '管理者'),
                ProfileMenuGroup(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: AppColors.ruriDark,
                      title: '管理者ログイン',
                      subtitle: '案件の投稿・編集ができます',
                      onTap: () {
                        context.push(RoutePaths.adminLogin);
                      },
                    ),
                    ProfileMenuTile(
                      icon: Icons.logout,
                      iconColor: AppColors.error,
                      title: '管理者ログアウト',
                      subtitle: isAnon ? '現在ログインしていません' : 'ログアウトして一般ユーザー表示に戻す',
                      isLast: true,
                      onTap: () async {
                        final auth = FirebaseAuth.instance;
                        await auth.signOut();
                        await auth.signInAnonymously();

                        if (!context.mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ログアウトしました（ゲストに戻りました）')),
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
