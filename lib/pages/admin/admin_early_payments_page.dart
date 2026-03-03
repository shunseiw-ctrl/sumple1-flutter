import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/services/payment_cycle_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';

/// 管理者向け即金申請一覧ページ
class AdminEarlyPaymentsPage extends StatefulWidget {
  final PaymentCycleService? paymentCycleService;
  final FirebaseFirestore? firestore;
  final NotificationService? notificationService;

  const AdminEarlyPaymentsPage({
    super.key,
    this.paymentCycleService,
    this.firestore,
    this.notificationService,
  });

  @override
  State<AdminEarlyPaymentsPage> createState() =>
      _AdminEarlyPaymentsPageState();
}

class _AdminEarlyPaymentsPageState extends State<AdminEarlyPaymentsPage> {
  late final PaymentCycleService _paymentService;
  late final FirebaseFirestore _db;
  late final NotificationService _notificationService;

  /// ワーカーUID -> 表示名キャッシュ
  final Map<String, String> _workerNameCache = {};

  @override
  void initState() {
    super.initState();
    _paymentService = widget.paymentCycleService ?? PaymentCycleService();
    _db = widget.firestore ?? FirebaseFirestore.instance;
    _notificationService = widget.notificationService ?? NotificationService();
    AnalyticsService.logScreenView('admin_early_payments');
  }

  /// ワーカー表示名を取得（キャッシュ付き）
  Future<String> _getWorkerName(String uid) async {
    if (_workerNameCache.containsKey(uid)) {
      return _workerNameCache[uid]!;
    }

    try {
      final doc = await _db
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

    _workerNameCache[uid] = context.l10n.adminEarlyPayments_nameNotSet;
    return context.l10n.adminEarlyPayments_nameNotSet;
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
    return context.l10n.adminEarlyPayments_yenFormat(buffer.toString());
  }

  Future<void> _approveRequest(String requestId, String workerUid) async {
    try {
      await _paymentService.approveEarlyPayment(requestId);
      await _notificationService.createNotification(
        targetUid: workerUid,
        title: context.l10n.adminEarlyPayments_notifyApprovedTitle,
        body: context.l10n.adminEarlyPayments_notifyApprovedBody,
        type: 'early_payment',
      );
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminEarlyPayments_snackApproved);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminEarlyPayments_snackApproveFailed);
      }
    }
  }

  Future<void> _showRejectDialog(String requestId, String workerUid) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminEarlyPayments_rejectReasonTitle),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            hintText: context.l10n.adminEarlyPayments_rejectReasonHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.adminEarlyPayments_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.adminEarlyPayments_rejectButton),
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
        ErrorHandler.showError(context, null, customMessage: context.l10n.adminEarlyPayments_rejectReasonRequired);
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
        title: context.l10n.adminEarlyPayments_notifyRejectedTitle,
        body: context.l10n.adminEarlyPayments_notifyRejectedBody(reason),
        type: 'early_payment',
      );
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminEarlyPayments_snackRejected);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminEarlyPayments_snackRejectFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.adminEarlyPayments_title),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('early_payment_requests')
            .where('status', isEqualTo: 'requested')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(context.l10n.adminEarlyPayments_loadError(snap.error.toString())));
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.flash_on,
              title: context.l10n.adminEarlyPayments_emptyTitle,
              description: context.l10n.adminEarlyPayments_emptyDescription,
              iconColor: context.appColors.warning,
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
                  final workerName = nameSnap.data ?? context.l10n.adminEarlyPayments_loading;
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
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.appColors.primaryPale,
                child:
                    Icon(Icons.person, color: context.appColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Text(
                  context.l10n.adminEarlyPayments_statusRequested,
                  style: const TextStyle(
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
              color: context.appColors.chipUnselected,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.adminEarlyPayments_targetMonth,
                      style: AppTextStyles.labelMedium,
                    ),
                    Text(
                      month,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.adminEarlyPayments_requestedAmount,
                      style: AppTextStyles.labelMedium,
                    ),
                    Text(
                      formatYen(requestedAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.adminEarlyPayments_fee,
                      style: AppTextStyles.labelMedium,
                    ),
                    Text(
                      '-${formatYen(fee)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.error,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.adminEarlyPayments_payoutAmount,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatYen(payout),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: context.appColors.primary,
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
              context.l10n.adminEarlyPayments_requestDate(dateStr),
              style: TextStyle(
                fontSize: 11,
                color: context.appColors.textHint,
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
                  label: Text(context.l10n.adminEarlyPayments_rejectLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appColors.error,
                    side: BorderSide(color: context.appColors.error),
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
                  label: Text(context.l10n.adminEarlyPayments_approveLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.success,
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
