import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

/// 管理者向け承認カード（資格・即金・本人確認で共通使用）
class AdminApprovalCard extends StatelessWidget {
  final String workerName;
  final String workerUid;
  final Widget statusBadge;
  final Widget content;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isProcessing;
  final String? approveLabel;
  final String? rejectLabel;

  const AdminApprovalCard({
    super.key,
    required this.workerName,
    required this.workerUid,
    required this.statusBadge,
    required this.content,
    this.onApprove,
    this.onReject,
    this.isProcessing = false,
    this.approveLabel,
    this.rejectLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.appColors.divider),
        boxShadow: [
          BoxShadow(
            color: context.appColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー: ワーカー情報 + ステータスバッジ
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.appColors.primaryPale,
                child: Icon(Icons.person, color: context.appColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName.isNotEmpty ? workerName : context.l10n.adminApproval_noName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UID: ${workerUid.length > 8 ? '${workerUid.substring(0, 8)}...' : workerUid}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              statusBadge,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // コンテンツ
          content,
          // アクションボタン
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(rejectLabel ?? context.l10n.adminApproval_reject),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appColors.error,
                        side: BorderSide(color: context.appColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (onApprove != null && onReject != null)
                  const SizedBox(width: 10),
                if (onApprove != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : onApprove,
                      icon: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(approveLabel ?? context.l10n.adminApproval_approve),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
