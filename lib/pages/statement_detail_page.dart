import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
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
      appBar: AppBar(title: const Text('明細詳細')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('monthly_statements')
            .doc(statementId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('エラー: ${snap.error}'));
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
                  color: AppColors.ruri,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('${stmt.month}月',
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
              const Text('案件明細',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              ...stmt.items.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.jobTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('完了日: ${item.completedDate}'),
                      trailing: Text('¥${_formatAmount(item.amount)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.ruri)),
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
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('即金申請済み（審査中）',
                          style: TextStyle(
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
              title: const Text('即金申請'),
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
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('申請する'),
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
                const SnackBar(content: Text('即金申請を送信しました')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('申請に失敗: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.flash_on),
        label: const Text('即金申請（手数料10%）',
            style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
