import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/l10n/app_localizations.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback onRetry;
  final IconData icon;
  final bool isCompact;

  const ErrorRetryWidget({
    super.key,
    this.title,
    this.message,
    required this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.isCompact = false,
  });

  factory ErrorRetryWidget.network({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    // i18n: errorRetry_networkErrorTitle, errorRetry_networkErrorMessage
    return ErrorRetryWidget(
      onRetry: onRetry,
      icon: Icons.wifi_off_rounded,
      isCompact: isCompact,
    );
  }

  factory ErrorRetryWidget.timeout({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    // i18n: errorRetry_timeoutTitle, errorRetry_timeoutMessage
    return ErrorRetryWidget(
      onRetry: onRetry,
      icon: Icons.timer_off_rounded,
      isCompact: isCompact,
    );
  }

  factory ErrorRetryWidget.general({
    required VoidCallback onRetry,
    String? message,
    bool isCompact = false,
  }) {
    // i18n: errorRetry_generalTitle, errorRetry_generalMessage
    return ErrorRetryWidget(
      message: message,
      onRetry: onRetry,
      icon: Icons.error_outline_rounded,
      isCompact: isCompact,
    );
  }

  factory ErrorRetryWidget.empty({
    required VoidCallback onRetry,
    String? title,
    String? message,
  }) {
    // i18n: errorRetry_emptyTitle, errorRetry_emptyMessage
    return ErrorRetryWidget(
      title: title,
      message: message,
      onRetry: onRetry,
      icon: Icons.search_off_rounded,
    );
  }

  String _resolveTitle(BuildContext context) {
    if (title != null) return title!;
    if (icon == Icons.wifi_off_rounded) return context.l10n.errorRetry_networkErrorTitle;
    if (icon == Icons.timer_off_rounded) return context.l10n.errorRetry_timeoutTitle;
    if (icon == Icons.search_off_rounded) return context.l10n.errorRetry_emptyTitle;
    return context.l10n.errorRetry_generalTitle;
  }

  String? _resolveMessage(BuildContext context) {
    if (message != null) return message;
    if (icon == Icons.wifi_off_rounded) return context.l10n.errorRetry_networkErrorMessage;
    if (icon == Icons.timer_off_rounded) return context.l10n.errorRetry_timeoutMessage;
    if (icon == Icons.search_off_rounded) return context.l10n.errorRetry_emptyMessage;
    return context.l10n.errorRetry_generalMessage;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isCompact) {
      return _buildCompact(context, l10n);
    }
    return _buildFull(context, l10n);
  }

  Widget _buildCompact(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: context.appColors.textHint),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _resolveTitle(context),
              style: AppTextStyles.labelLarge.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            _buildRetryButton(compact: true, l10n: l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, AppLocalizations l10n) {
    final resolvedMessage = _resolveMessage(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.06),
                    Colors.red.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _resolveTitle(context),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall,
            ),
            if (resolvedMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                resolvedMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _buildRetryButton(compact: false, l10n: l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton({required bool compact, required AppLocalizations l10n}) {
    return Builder(
      builder: (context) {
        return SizedBox(
          width: compact ? null : double.infinity,
          height: compact ? 36 : 48,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              l10n.retry,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 18 : AppSpacing.buttonRadius),
              ),
            ),
          ),
        );
      },
    );
  }
}
