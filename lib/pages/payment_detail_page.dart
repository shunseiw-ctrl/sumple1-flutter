import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/data/models/payment_model.dart';

class PaymentDetailPage extends StatelessWidget {
  final String paymentId;

  const PaymentDetailPage({super.key, required this.paymentId});

  String _formatYen(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return '¥${buf.toString()}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'succeeded':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '支払い詳細',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('支払い情報が見つかりません'));
          }

          final payment = PaymentModel.fromFirestore(snap.data!);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ステータスカード
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _statusColor(payment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _statusColor(payment.status).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      payment.status == 'succeeded'
                          ? Icons.check_circle
                          : payment.status == 'failed'
                              ? Icons.cancel
                              : Icons.pending,
                      size: 48,
                      color: _statusColor(payment.status),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      payment.statusLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _statusColor(payment.status),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 金額詳細
              _DetailCard(
                children: [
                  _DetailRow(label: '案件名', value: payment.projectNameSnapshot ?? '-'),
                  const Divider(height: 24),
                  _DetailRow(label: '支払い金額', value: _formatYen(payment.amount), bold: true),
                  _DetailRow(label: 'プラットフォーム手数料', value: _formatYen(payment.platformFee)),
                  _DetailRow(label: '受取金額', value: _formatYen(payment.netAmount), bold: true),
                  const Divider(height: 24),
                  _DetailRow(label: '決済ステータス', value: payment.statusLabel),
                  _DetailRow(label: '振込ステータス', value: payment.payoutStatusLabel),
                  if (payment.createdAt != null) ...[
                    const Divider(height: 24),
                    _DetailRow(
                      label: '作成日時',
                      value: '${payment.createdAt!.year}/${payment.createdAt!.month.toString().padLeft(2, '0')}/${payment.createdAt!.day.toString().padLeft(2, '0')} '
                          '${payment.createdAt!.hour.toString().padLeft(2, '0')}:${payment.createdAt!.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EB)),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
