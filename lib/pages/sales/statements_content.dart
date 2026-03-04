import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/utils/currency_utils.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';

/// 明細タブ
class StatementsContent extends StatefulWidget {
  final String uid;
  const StatementsContent({super.key, required this.uid});

  @override
  State<StatementsContent> createState() => _StatementsContentState();
}

class _StatementsContentState extends State<StatementsContent> {
  Key _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: _refreshKey,
      stream: FirebaseFirestore.instance
          .collection('monthly_statements')
          .where('workerUid', isEqualTo: widget.uid)
          .orderBy('month', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SkeletonList();
        }
        if (snap.hasError) {
          return ErrorRetryWidget.general(
            onRetry: () => setState(() => _refreshKey = UniqueKey()),
            message: '${snap.error}',
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: context.l10n.sales_noStatements,
            description: context.l10n.sales_noStatementsDescription,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final month = (data['month'] ?? '').toString();
            final total = int.tryParse((data['totalAmount'] ?? '0').toString()) ?? 0;
            final status = (data['status'] ?? 'draft').toString();
            final statusLabel = switch (status) {
              'draft' => context.l10n.sales_statusDraft,
              'confirmed' => context.l10n.common_confirmed,
              'paid' => context.l10n.sales_statusPaid,
              _ => status,
            };
            final statusColor = switch (status) {
              'paid' => context.appColors.success,
              'confirmed' => context.appColors.primary,
              _ => context.appColors.textSecondary,
            };

            return Semantics(
              label: '${context.l10n.sales_monthStatement(month)}、${CurrencyUtils.formatYen(total)}、$statusLabel',
              child: Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: Icon(Icons.receipt_long, color: context.appColors.primary),
                  title: Text(context.l10n.sales_monthStatement(month),
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text('${context.l10n.sales_total}: ${CurrencyUtils.formatYen(total)}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  onTap: () {
                    context.push(RoutePaths.statementDetailPath(docs[i].id));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
