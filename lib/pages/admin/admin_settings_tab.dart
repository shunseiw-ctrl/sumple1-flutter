import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';

/// 管理者設定タブ
class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('admin_settings');
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    final confirmed = await ErrorHandler.showConfirmDialog(
      context,
      title: context.l10n.adminSettings_logoutTitle,
      message: context.l10n.adminSettings_logoutConfirm,
      isDangerous: true,
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go(RoutePaths.home);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: AppSpacing.listInsets,
      children: [
        // プロフィール情報
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: context.appColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: context.appColors.primaryPale,
                child: Icon(Icons.admin_panel_settings,
                    color: context.appColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? context.l10n.adminSettings_admin,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 設定項目
        _SettingsSection(
          children: [
            _SettingsItem(
              icon: Icons.notifications_outlined,
              title: context.l10n.adminSettings_notifications,
              onTap: () => context.push(RoutePaths.notifications),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // アプリ情報
        _SettingsSection(
          children: [
            _SettingsItem(
              icon: Icons.info_outline,
              title: context.l10n.adminSettings_appVersion,
              trailing: Text(
                _appVersion,
                style: TextStyle(
                  fontSize: 13,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
            _SettingsItem(
              icon: Icons.description_outlined,
              title: context.l10n.adminSettings_legal,
              onTap: () => context.push(RoutePaths.legalIndex),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ログアウト
        _SettingsSection(
          children: [
            _SettingsItem(
              icon: Icons.logout,
              title: context.l10n.adminSettings_logout,
              iconColor: context.appColors.error,
              titleColor: context.appColors.error,
              onTap: _logout,
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;
  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  color: context.appColors.divider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? context.appColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? context.appColors.textPrimary,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: context.appColors.textHint)
              : null),
      onTap: onTap,
    );
  }
}
