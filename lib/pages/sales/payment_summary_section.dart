import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/utils/currency_utils.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'sales_shared.dart';

/// 管理者用支払いサマリーセクション
class PaymentSummarySection extends StatelessWidget {
  const PaymentSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('earnings')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.base), child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return ErrorRetryWidget.general(
            onRetry: () {},
            message: '${snap.error}',
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: AppShadows.subtle,
            ),
            child: Center(child: Text(context.l10n.sales_noPaymentData, style: AppTextStyles.bodySmall)),
          );
        }

        final monthlyMap = <String, Map<String, dynamic>>{};
        for (final doc in docs) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          String monthKey = context.l10n.common_unknown;
          if (createdAt is Timestamp) {
            final d = createdAt.toDate();
            monthKey = '${d.year}/${d.month.toString().padLeft(2, '0')}';
          }

          if (!monthlyMap.containsKey(monthKey)) {
            monthlyMap[monthKey] = {'total': 0, 'count': 0, 'paid': 0, 'unpaid': 0};
          }

          final amount = int.tryParse((data['amount'] ?? '0').toString()) ?? 0;
          final isPaid = data['paymentStatus'] == 'paid';

          monthlyMap[monthKey]!['total'] = (monthlyMap[monthKey]!['total'] as int) + amount;
          monthlyMap[monthKey]!['count'] = (monthlyMap[monthKey]!['count'] as int) + 1;
          if (isPaid) {
            monthlyMap[monthKey]!['paid'] = (monthlyMap[monthKey]!['paid'] as int) + amount;
          } else {
            monthlyMap[monthKey]!['unpaid'] = (monthlyMap[monthKey]!['unpaid'] as int) + amount;
          }
        }

        final sortedMonths = monthlyMap.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          children: sortedMonths.map((month) {
            final info = monthlyMap[month]!;
            final total = info['total'] as int;
            final count = info['count'] as int;
            final paid = info['paid'] as int;
            final unpaid = info['unpaid'] as int;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 18, color: context.appColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(month, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                      const Spacer(),
                      Text('$count${context.l10n.common_itemsCount}', style: AppTextStyles.labelMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: MiniStat(label: context.l10n.sales_total, value: CurrencyUtils.formatYen(total), color: context.appColors.textPrimary),
                      ),
                      Expanded(
                        child: MiniStat(label: context.l10n.sales_paid, value: CurrencyUtils.formatYen(paid), color: context.appColors.success),
                      ),
                      Expanded(
                        child: MiniStat(label: context.l10n.sales_unpaid, value: CurrencyUtils.formatYen(unpaid), color: context.appColors.warning),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
