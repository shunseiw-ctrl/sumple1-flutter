import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sumple1/core/extensions/build_context_extensions.dart';
import '../core/services/payment_cycle_service.dart';
import '../core/utils/haptic_utils.dart';
import '../data/models/early_payment_request_model.dart';
import '../data/models/monthly_statement_model.dart';

/// 月次明細詳細ページ
class StatementDetailPage extends StatelessWidget {
  final String statementId;

  const StatementDetailPage({super.key, required this.statementId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.statementDetail_title)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('monthly_statements')
            .doc(statementId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(context.l10n.statementDetail_error(snap.error.toString())));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final stmt =
              MonthlyStatementModel.fromFirestore(snap.data!);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(context.l10n.statementDetail_monthLabel(stmt.month.toString()),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('¥${_formatAmount(stmt.totalAmount)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(stmt.statusLabel,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 明細行
              Text(context.l10n.statementDetail_jobDetails,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              ...stmt.items.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.jobTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(context.l10n.statementDetail_completedDate(item.completedDate)),
                      trailing: Text('¥${_formatAmount(item.amount)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: context.appColors.primary)),
                    ),
                  )),

              const SizedBox(height: 16),

              // 即金申請ボタン
              if (stmt.status == 'confirmed' && !stmt.earlyPaymentRequested)
                _EarlyPaymentButton(
                  statementId: statementId,
                  totalAmount: stmt.totalAmount,
                ),

              if (stmt.earlyPaymentRequested)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(context.l10n.statementDetail_earlyPaymentPending,
                          style: const TextStyle(
                              color: Colors.orange, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatAmount(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class _EarlyPaymentButton extends StatelessWidget {
  final String statementId;
  final int totalAmount;

  const _EarlyPaymentButton({
    required this.statementId,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final fee = EarlyPaymentRequestModel.calculateFee(totalAmount);
    final payout = EarlyPaymentRequestModel.calculatePayout(totalAmount);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(context.l10n.statementDetail_earlyPaymentTitle),
              // TODO: i18n - statementDetail_earlyPaymentConfirm needs {amount}, {fee}, {payout} params
              content: Text(
                '手数料10%が差し引かれます。\n\n'
                '申請額: ¥$totalAmount\n'
                '手数料: ¥$fee\n'
                '受取額: ¥$payout\n\n'
                '申請しますか？',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.l10n.common_cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.l10n.statementDetail_applyButton),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            try {
              await PaymentCycleService().requestEarlyPayment(
                statementId: statementId,
                requestedAmount: totalAmount,
              );
              AppHaptics.success();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.statementDetail_earlyPaymentSuccess)),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${context.l10n.statementDetail_earlyPaymentError}: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.flash_on),
        label: Text(context.l10n.statementDetail_earlyPaymentButton,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
