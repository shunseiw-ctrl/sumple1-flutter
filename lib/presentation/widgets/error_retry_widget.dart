import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
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
    return ErrorRetryWidget(
      title: 'ネットワークエラー',
      message: 'インターネット接続を確認して\nもう一度お試しください',
      onRetry: onRetry,
      icon: Icons.wifi_off_rounded,
      isCompact: isCompact,
    );
  }

  factory ErrorRetryWidget.timeout({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return ErrorRetryWidget(
      title: 'タイムアウト',
      message: 'サーバーへの接続に時間がかかっています\nもう一度お試しください',
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
    return ErrorRetryWidget(
      title: 'エラーが発生しました',
      message: message ?? 'しばらく経ってからもう一度お試しください',
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
    return ErrorRetryWidget(
      title: title ?? 'データが見つかりません',
      message: message ?? '条件を変更して再検索してください',
      onRetry: onRetry,
      icon: Icons.search_off_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isCompact) {
      return _buildCompact(l10n);
    }
    return _buildFull(l10n);
  }

  Widget _buildCompact(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title ?? l10n.errorLabel,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            _buildRetryButton(compact: true, l10n: l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(AppLocalizations l10n) {
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
              title ?? l10n.errorGeneric,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
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
          backgroundColor: AppColors.ruri,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 18 : AppSpacing.buttonRadius),
          ),
        ),
      ),
    );
  }
}
