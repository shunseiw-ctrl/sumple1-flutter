import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/config/feature_flags.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/utils/currency_utils.dart';
import 'sales_shared.dart';

/// 支払い履歴セクション
class PaymentHistorySection extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  const PaymentHistorySection({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return const SizedBox.shrink();

    return SalesShadowCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 20, color: context.appColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.sales_paymentHistory,
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...docs.take(20).map((doc) {
              final data = doc.data();
              final amount = (data['amount'] is int) ? (data['amount'] as int) : 0;
              final paymentStatus = (data['paymentStatus'] ?? '').toString();
              final paymentId = (data['paymentId'] ?? '').toString();
              final isPaid = paymentStatus == 'paid';

              DateTime? confirmedAt;
              final ts = data['payoutConfirmedAt'];
              if (ts is Timestamp) confirmedAt = ts.toDate();

              final dateText = confirmedAt != null
                  ? '${confirmedAt.year}/${confirmedAt.month.toString().padLeft(2, '0')}/${confirmedAt.day.toString().padLeft(2, '0')}'
                  : '';

              final canNavigate = paymentId.isNotEmpty && FeatureFlags.enableStripePayments;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  onTap: canNavigate
                      ? () {
                          context.push(RoutePaths.paymentDetailPath(paymentId));
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyUtils.formatYen(amount),
                                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (dateText.isNotEmpty)
                                Text(
                                  dateText,
                                  style: AppTextStyles.labelSmall.copyWith(color: context.appColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? context.appColors.success.withValues(alpha: 0.1)
                                : context.appColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          ),
                          child: Text(
                            isPaid ? '${context.l10n.common_transferred} ✓' : context.l10n.common_confirmed,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isPaid ? context.appColors.success : context.appColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (canNavigate)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.chevron_right, size: 18, color: context.appColors.textHint),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
