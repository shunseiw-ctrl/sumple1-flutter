import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/services/payment_cycle_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';

/// 管理者向け即金申請一覧ページ
class AdminEarlyPaymentsPage extends StatefulWidget {
  const AdminEarlyPaymentsPage({super.key});

  @override
  State<AdminEarlyPaymentsPage> createState() =>
      _AdminEarlyPaymentsPageState();
}

class _AdminEarlyPaymentsPageState extends State<AdminEarlyPaymentsPage> {
  final PaymentCycleService _paymentService = PaymentCycleService();
  final NotificationService _notificationService = NotificationService();

  /// ワーカーUID -> 表示名キャッシュ
  final Map<String, String> _workerNameCache = {};

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('admin_early_payments');
  }

  /// ワーカー表示名を取得（キャッシュ付き）
  Future<String> _getWorkerName(String uid) async {
    if (_workerNameCache.containsKey(uid)) {
      return _workerNameCache[uid]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null) {
        final displayName = (data['displayName'] ?? '').toString().trim();
        if (displayName.isNotEmpty) {
          _workerNameCache[uid] = displayName;
          return displayName;
        }
        final familyName = (data['familyName'] ?? '').toString().trim();
        final givenName = (data['givenName'] ?? '').toString().trim();
        if (familyName.isNotEmpty || givenName.isNotEmpty) {
          final name = '$familyName $givenName'.trim();
          _workerNameCache[uid] = name;
          return name;
        }
      }
    } catch (_) {}

    _workerNameCache[uid] = '名前未設定';
    return '名前未設定';
  }

  /// 金額フォーマット（カンマ区切り + 円）
  String _formatYen(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()}円';
  }

  Future<void> _approveRequest(String requestId, String workerUid) async {
    try {
      await _paymentService.approveEarlyPayment(requestId);
      await _notificationService.createNotification(
        targetUid: workerUid,
        title: '即金申請が承認されました',
        body: '即金申請が承認されました。まもなく振り込まれます。',
        type: 'early_payment',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('即金申請を承認しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('承認に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(String requestId, String workerUid) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('却下理由'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: '却下の理由を入力してください',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('却下する'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonCtrl.dispose();
      return;
    }

    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();

    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('却下理由を入力してください')),
        );
      }
      return;
    }

    try {
      await _paymentService.rejectEarlyPayment(
        requestId: requestId,
        reason: reason,
      );
      await _notificationService.createNotification(
        targetUid: workerUid,
        title: '即金申請が却下されました',
        body: '即金申請が却下されました。理由: $reason',
        type: 'early_payment',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('即金申請を却下しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('却下に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('即金申請一覧'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('early_payment_requests')
            .where('status', isEqualTo: 'requested')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('読み込みエラー: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.flash_on,
              title: '承認待ちの即金申請はありません',
              description: 'ワーカーが即金申請を行うと、ここに表示されます。',
              iconColor: AppColors.warning,
            );
          }

          return ListView.separated(
            padding: AppSpacing.listInsets,
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final workerUid = (data['workerUid'] ?? '').toString();
              final month = (data['month'] ?? '').toString();
              final requestedAmount =
                  (data['requestedAmount'] ?? 0) as int;
              final fee = (data['earlyPaymentFee'] ?? 0) as int;
              final payout = (data['payoutAmount'] ?? 0) as int;
              final createdAt = data['createdAt'];
              String dateStr = '';
              if (createdAt is Timestamp) {
                final d = createdAt.toDate();
                dateStr =
                    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
              }

              return FutureBuilder<String>(
                future: _getWorkerName(workerUid),
                builder: (context, nameSnap) {
                  final workerName = nameSnap.data ?? '読み込み中...';
                  return _EarlyPaymentCard(
                    workerName: workerName,
                    workerUid: workerUid,
                    month: month,
                    requestedAmount: requestedAmount,
                    fee: fee,
                    payout: payout,
                    dateStr: dateStr,
                    formatYen: _formatYen,
                    onApprove: () =>
                        _approveRequest(doc.id, workerUid),
                    onReject: () =>
                        _showRejectDialog(doc.id, workerUid),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EarlyPaymentCard extends StatelessWidget {
  final String workerName;
  final String workerUid;
  final String month;
  final int requestedAmount;
  final int fee;
  final int payout;
  final String dateStr;
  final String Function(int) formatYen;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _EarlyPaymentCard({
    required this.workerName,
    required this.workerUid,
    required this.month,
    required this.requestedAmount,
    required this.fee,
    required this.payout,
    required this.dateStr,
    required this.formatYen,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.ruriPale,
                child:
                    Icon(Icons.person, color: AppColors.ruri, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'UID: ${workerUid.length > 8 ? '${workerUid.substring(0, 8)}...' : workerUid}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: const Text(
                  '申請中',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chipUnselected,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '対象月',
                      style: AppTextStyles.labelMedium,
                    ),
                    Text(
                      month,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '申請額',
                      style: AppTextStyles.labelMedium,
                    ),
                    Text(
                      formatYen(requestedAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '手数料 (10%)',
                      style: AppTextStyles.labelMedium,
                    ),
                    Text(
                      '-${formatYen(fee)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '支払額',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatYen(payout),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ruri,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '申請日時: $dateStr',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('却下'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('承認'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
