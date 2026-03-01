import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_login_page.dart';
import 'identity_verification_page.dart';
import 'my_profile_page.dart';
import 'stripe_onboarding_page.dart';
import 'account_settings_page.dart';
import 'faq_page.dart';
import 'contact_page.dart';
import 'legal_page.dart';
import '../core/services/line_auth_service.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isAnonymous(User? user) => user == null || user.isAnonymous;

  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 3);

  bool get _isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('profile');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  String _authErrorMessageJa(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません';
      case 'email-already-in-use':
        return 'そのメールアドレスは既に使われています';
      case 'weak-password':
        return 'パスワードが弱すぎます（6文字以上推奨）';
      case 'operation-not-allowed':
        return 'Firebase側でメール/パスワード認証が有効化されていません';
      default:
        return '認証エラー: ${e.code}';
    }
  }

  Future<void> _showSnack(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showEmailAuthDialog() async {
    bool obscure = true;
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            Future<void> signIn() async {
              if (_isLockedOut) {
                await _showSnack('ログイン試行回数の上限に達しました。しばらくお待ちください');
                return;
              }

              final email = _emailController.text.trim();
              final pass = _passController.text;

              if (email.isEmpty || pass.isEmpty) {
                await _showSnack('メールアドレスとパスワードを入力してください');
                return;
              }

              setLocalState(() => isLoading = true);
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: pass,
                );

                _failedAttempts = 0;
                _lockoutUntil = null;

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) setState(() {});
                await _showSnack('ログインしました');
              } on FirebaseAuthException catch (e) {
                _failedAttempts++;
                if (_failedAttempts >= _maxAttempts) {
                  _lockoutUntil = DateTime.now().add(_lockoutDuration);
                }
                await _showSnack(_authErrorMessageJa(e));
              } catch (e) {
                _failedAttempts++;
                if (_failedAttempts >= _maxAttempts) {
                  _lockoutUntil = DateTime.now().add(_lockoutDuration);
                }
                await _showSnack('ログインに失敗しました');
              } finally {
                if (dialogContext.mounted) {
                  setLocalState(() => isLoading = false);
                }
              }
            }

            Future<void> signUp() async {
              final email = _emailController.text.trim();
              final pass = _passController.text;

              if (email.isEmpty || pass.isEmpty) {
                await _showSnack('メールアドレスとパスワードを入力してください');
                return;
              }
              if (pass.length < 6) {
                await _showSnack('パスワードは6文字以上にしてください');
                return;
              }

              setLocalState(() => isLoading = true);
              try {
                final current = FirebaseAuth.instance.currentUser;

                if (current != null && current.isAnonymous) {
                  final cred = EmailAuthProvider.credential(
                    email: email,
                    password: pass,
                  );
                  await current.linkWithCredential(cred);
                } else {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email,
                    password: pass,
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) setState(() {});
                await _showSnack('登録しました（ログイン済み）');
              } on FirebaseAuthException catch (e) {
                await _showSnack(_authErrorMessageJa(e));
              } catch (e) {
                await _showSnack('登録に失敗しました');
              } finally {
                if (dialogContext.mounted) {
                  setLocalState(() => isLoading = false);
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              title: Text('メールでログイン', style: AppTextStyles.headingSmall),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'メールアドレス',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                        borderSide: BorderSide(color: AppColors.ruri, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.ruriSurface.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: Semantics(
                        button: true,
                        label: obscure ? 'パスワードを表示' : 'パスワードを隠す',
                        child: IconButton(
                          onPressed: () => setLocalState(() => obscure = !obscure),
                          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                        borderSide: BorderSide(color: AppColors.ruri, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.ruriSurface.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoading) const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 8),
                  Text(
                    '新規登録もこの画面からできます',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: isLoading ? null : signUp,
                  child: const Text('新規登録'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : signIn,
                  child: const Text('ログイン'),
                ),
              ],
            );
          },
        );
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
        padding: EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.pagePadding, AppSpacing.pagePadding, 24),
        children: [
          StaggeredFadeSlide(
            index: 0,
            child: _ProfileHeaderCard(
              displayName: displayName,
              subtitle: isAnon ? 'ログインすると応募・チャットが使えます' : 'ログイン済み',
              isLoggedIn: !isAnon,
            ),
          ),
          const SizedBox(height: 16),

          if (isAnon) ...[
            StaggeredFadeSlide(
              index: 1,
              child: _InfoBanner(
                title: 'ログインが必要です',
                message: '応募・チャットなど一部機能を利用するにはログインが必要です。',
                buttonText: 'ログインする',
                onPressed: _showEmailAuthDialog,
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
                const _SectionHeader(title: 'アカウント'),
                _MenuGroup(
                  children: [
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      iconColor: AppColors.ruri,
                      title: 'アカウント設定',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                        );
                      },
                    ),
                    _MenuTile(
                      icon: Icons.badge_outlined,
                      iconColor: AppColors.info,
                      title: 'あなたのプロフィール',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyProfilePage()),
                        );
                      },
                    ),
                    _MenuTile(
                      icon: Icons.verified_user_outlined,
                      iconColor: AppColors.success,
                      title: '本人確認',
                      subtitle: '身分証明書と顔写真を提出',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const IdentityVerificationPage()),
                        );
                      },
                    ),
                    _MenuTile(
                      icon: Icons.account_balance_outlined,
                      iconColor: const Color(0xFF635BFF),
                      title: 'Stripe口座設定',
                      subtitle: '報酬の受取口座を設定',
                      isLast: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StripeOnboardingPage(
                            email: user?.email,
                          )),
                        );
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
                const _SectionHeader(title: 'サポート'),
                _MenuGroup(
                  children: [
                    _MenuTile(
                      icon: Icons.help_outline,
                      iconColor: AppColors.warning,
                      title: 'よくある質問',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FaqPage()),
                        );
                      },
                    ),
                    _MenuTile(
                      icon: Icons.mail_outline,
                      iconColor: AppColors.ruri,
                      title: 'お問い合わせ',
                      isLast: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContactPage()),
                        );
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
                const _SectionHeader(title: 'その他'),
                _MenuGroup(
                  children: [
                    _MenuTile(
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
                    _MenuTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.textSecondary,
                      title: 'プライバシーポリシー',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalPage(
                              title: 'プライバシーポリシー',
                              htmlContent: LegalPage.privacyPolicyHtml,
                            ),
                          ),
                        );
                      },
                    ),
                    _MenuTile(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.textSecondary,
                      title: '利用規約',
                      isLast: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalPage(
                              title: '利用規約',
                              htmlContent: LegalPage.termsHtml,
                            ),
                          ),
                        );
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
                const _SectionHeader(title: '管理者'),
                _MenuGroup(
                  children: [
                    _MenuTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: AppColors.ruriDark,
                      title: '管理者ログイン',
                      subtitle: '案件の投稿・編集ができます',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                        );
                      },
                    ),
                    _MenuTile(
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

class _ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final bool isLoggedIn;

  const _ProfileHeaderCard({
    required this.displayName,
    required this.subtitle,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Semantics(
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.ruriPale,
                  child: Icon(Icons.person, color: AppColors.ruri, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Semantics(
            label: 'ステータス: ${isLoggedIn ? "ログイン済み" : "ゲスト"}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLoggedIn ? AppColors.successLight : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoggedIn) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    isLoggedIn ? 'ログイン済み' : 'ゲスト',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isLoggedIn ? AppColors.success : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _InfoBanner({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 140,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 6),
                  Text(message, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      child: Text(buttonText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.ruri,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.sectionTitle,
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.subtle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = const Color(0xFF6B7280),
    this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: subtitle != null ? '$title、$subtitle' : title,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(title, style: AppTextStyles.bodyMedium),
            subtitle: subtitle == null
                ? null
                : Text(subtitle!, style: AppTextStyles.labelSmall),
            trailing: Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            onTap: onTap,
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),
      ],
    );
  }
}
