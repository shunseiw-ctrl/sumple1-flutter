import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumple1/core/services/account_linking_service.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/l10n/app_localizations.dart';

/// アカウント連携セクション（プロフィール設定ページ内）
class AccountLinkingSection extends StatefulWidget {
  const AccountLinkingSection({super.key});

  @override
  State<AccountLinkingSection> createState() => _AccountLinkingSectionState();
}

class _AccountLinkingSectionState extends State<AccountLinkingSection> {
  final _linkingService = AccountLinkingService();
  bool _isLoading = false;

  List<String> get _linkedProviders => _linkingService.getLinkedProviders();

  bool _isLinked(String providerId) => _linkedProviders.contains(providerId);

  Future<void> _linkGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _linkingService.linkGoogle();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.accountLinking_linked)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError(e.code == 'credential-already-in-use'
            ? AppLocalizations.of(context)!.accountLinking_alreadyInUse
            : e.message ?? '');
      }
    } catch (e) {
      Logger.error('Link Google failed', tag: 'AccountLinkingSection', error: e);
      if (mounted) _showError('Google連携エラー: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _linkApple() async {
    setState(() => _isLoading = true);
    try {
      await _linkingService.linkApple();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.accountLinking_linked)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError(e.code == 'credential-already-in-use'
            ? AppLocalizations.of(context)!.accountLinking_alreadyInUse
            : e.message ?? '');
      }
    } catch (e) {
      Logger.error('Link Apple failed', tag: 'AccountLinkingSection', error: e);
      if (mounted) _showError('Apple連携エラー: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlinkProvider(String providerId) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountLinking_unlink),
        content: Text(l10n.accountLinking_unlinkConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.accountLinking_unlink),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _linkingService.unlinkProvider(providerId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('cannot_unlink_last')
            ? l10n.accountLinking_cannotUnlinkLast
            : e.toString();
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l10n.accountLinking_title,
            style: AppTextStyles.headingSmall.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: AppShadows.subtle,
          ),
          child: Column(
            children: [
              // Google
              _ProviderTile(
                icon: Icons.g_mobiledata,
                iconColor: const Color(0xFF4285F4),
                label: 'Google',
                isLinked: _isLinked('google.com'),
                linkLabel: l10n.accountLinking_linkGoogle,
                onLink: _isLoading ? null : _linkGoogle,
                onUnlink: _isLoading ? null : () => _unlinkProvider('google.com'),
                canUnlink: _linkedProviders.length > 1,
              ),
              Divider(height: 1, color: context.appColors.divider),
              // Apple
              _ProviderTile(
                icon: Icons.apple,
                iconColor: context.appColors.textPrimary,
                label: 'Apple',
                isLinked: _isLinked('apple.com'),
                linkLabel: l10n.accountLinking_linkApple,
                onLink: _isLoading ? null : _linkApple,
                onUnlink: _isLoading ? null : () => _unlinkProvider('apple.com'),
                canUnlink: _linkedProviders.length > 1,
              ),
              Divider(height: 1, color: context.appColors.divider),
              // LINE
              _ProviderTile(
                icon: Icons.chat_bubble,
                iconColor: AppColors.lineGreen,
                label: 'LINE',
                isLinked: _isLinked('line'),
                linkLabel: l10n.accountLinking_linkLine,
                onLink: null, // LINE リンクは現状サーバー側で自動
                onUnlink: null,
                canUnlink: false,
              ),
              Divider(height: 1, color: context.appColors.divider),
              // Email
              _ProviderTile(
                icon: Icons.email_outlined,
                iconColor: context.appColors.primary,
                label: 'Email',
                isLinked: _isLinked('password'),
                linkLabel: null,
                onLink: null,
                onUnlink: null,
                canUnlink: false,
              ),
              Divider(height: 1, color: context.appColors.divider),
              // Phone
              _ProviderTile(
                icon: Icons.phone,
                iconColor: context.appColors.primary,
                label: 'Phone',
                isLinked: _isLinked('phone'),
                linkLabel: null,
                onLink: null,
                onUnlink: null,
                canUnlink: false,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isLinked;
  final String? linkLabel;
  final VoidCallback? onLink;
  final VoidCallback? onUnlink;
  final bool canUnlink;
  final bool isLast;

  const _ProviderTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isLinked,
    required this.linkLabel,
    required this.onLink,
    required this.onUnlink,
    required this.canUnlink,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          if (isLinked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.appColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.accountLinking_linked,
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.appColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (canUnlink && onUnlink != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onUnlink,
                child: Icon(
                  Icons.link_off,
                  size: 20,
                  color: context.appColors.textHint,
                ),
              ),
            ],
          ] else if (linkLabel != null && onLink != null) ...[
            TextButton(
              onPressed: onLink,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Text(
                linkLabel!,
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.appColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else if (!isLinked) ...[
            Text(
              '-',
              style: AppTextStyles.labelSmall.copyWith(
                color: context.appColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
