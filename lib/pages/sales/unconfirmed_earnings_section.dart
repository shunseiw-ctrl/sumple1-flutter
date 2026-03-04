import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'sales_shared.dart';

/// 未確定の報酬セクション（N+1修正: バッチクエリ）
class UnconfirmedEarningsSection extends StatelessWidget {
  final String uid;
  const UnconfirmedEarningsSection({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    // 単一FutureBuilderでバッチ取得（N+1修正）
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUnconfirmed(db, uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snap.hasError) {
          return ErrorRetryWidget.general(
            onRetry: () {},
            message: '${snap.error}',
          );
        }

        final unconfirmed = snap.data ?? [];
        if (unconfirmed.isEmpty) return const SizedBox.shrink();

        return SalesShadowCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pending_actions, size: 20, color: context.appColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.sales_unconfirmedEarnings,
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.appColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                      ),
                      child: Text(
                        '${unconfirmed.length}${context.l10n.common_itemsCount}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.appColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...unconfirmed.map((data) {
                  final jobTitle = (data['jobTitleSnapshot'] ?? context.l10n.common_job).toString();
                  final status = (data['status'] ?? '').toString();
                  final statusLabel = status == 'done' ? context.l10n.common_completed : context.l10n.sales_constructionCompleted;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            jobTitle,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.appColors.chipUnselected,
                            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          ),
                          child: Text(
                            statusLabel,
                            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.sales_earningsNote,
                  style: AppTextStyles.labelSmall.copyWith(color: context.appColors.textHint),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// N+1修正: バッチクエリで取得
  static Future<List<Map<String, dynamic>>> _fetchUnconfirmed(
    FirebaseFirestore db,
    String uid,
  ) async {
    // 完了/done の応募を取得
    final appSnap = await db
        .collection('applications')
        .where('applicantUid', isEqualTo: uid)
        .where('status', whereIn: ['completed', 'done'])
        .get();
    if (appSnap.docs.isEmpty) return [];

    // earningsからapplicationIdをバッチ取得
    final earningsSnap = await db
        .collection('earnings')
        .where('uid', isEqualTo: uid)
        .get();
    final earningsAppIds = <String>{};
    for (final doc in earningsSnap.docs) {
      final appId = (doc.data()['applicationId'] ?? '').toString();
      if (appId.isNotEmpty) earningsAppIds.add(appId);
    }

    // earningsが無いapplication = 未確定
    return appSnap.docs
        .where((d) => !earningsAppIds.contains(d.id))
        .map((d) => d.data())
        .toList();
  }
}
