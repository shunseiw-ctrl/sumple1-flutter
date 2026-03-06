import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/providers/admin_approval_provider.dart';
import 'package:sumple1/core/providers/admin_pending_counts_provider.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/qualification_service.dart';
import 'package:sumple1/core/services/payment_cycle_service.dart';
import 'package:sumple1/core/services/worker_name_resolver.dart';
import 'package:sumple1/core/utils/currency_utils.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';
import 'package:sumple1/presentation/widgets/admin_approval_card.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/load_more_button.dart';
import 'package:sumple1/presentation/widgets/reject_reason_dialog.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';

/// 統合承認センタータブ
class AdminApprovalCenterTab extends ConsumerStatefulWidget {
  const AdminApprovalCenterTab({super.key});

  @override
  ConsumerState<AdminApprovalCenterTab> createState() =>
      _AdminApprovalCenterTabState();
}

class _AdminApprovalCenterTabState
    extends ConsumerState<AdminApprovalCenterTab> {
  ApprovalType _selectedType = ApprovalType.qualification;
  late final WorkerNameResolver _nameResolver;
  late final QualificationService _qualificationService;
  late final PaymentCycleService _paymentService;
  late final ManualEkycService _ekycService;
  late final NotificationService _notificationService;
  final Map<String, String> _resolvedNames = {};
  final Set<String> _processingIds = {};

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _nameResolver = WorkerNameResolver();
    _qualificationService = QualificationService();
    _paymentService = PaymentCycleService();
    _ekycService = ManualEkycService();
    _notificationService = NotificationService();
    AnalyticsService.logScreenView('admin_approval_center');
  }

  Future<void> _resolveWorkerNames(List<ApprovalItem> items) async {
    final uids = items
        .map((i) => i.workerUid)
        .where((uid) => uid.isNotEmpty && !_resolvedNames.containsKey(uid))
        .toSet()
        .toList();

    if (uids.isEmpty) return;

    final names = await _nameResolver.resolveNames(uids);
    if (mounted) {
      setState(() => _resolvedNames.addAll(names));
    }
  }

  Future<void> _approveQualification(ApprovalItem item) async {
    if (_processingIds.contains(item.id)) return;
    setState(() => _processingIds.add(item.id));

    try {
      await _qualificationService.approve(
        targetUid: item.workerUid,
        qualificationId: item.id,
      );
      ref.read(adminApprovalProvider(ApprovalType.qualification).notifier).removeItem(item.id);
      ref.invalidate(adminPendingCountsProvider);
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminQualifications_approveSuccess(
          (item.data['name'] ?? '').toString(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminQualifications_approveError);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  Future<void> _rejectQualification(ApprovalItem item) async {
    final reason = await showRejectReasonDialog(context);
    if (reason == null) return;

    if (_processingIds.contains(item.id)) return;
    setState(() => _processingIds.add(item.id));

    try {
      await _qualificationService.reject(
        targetUid: item.workerUid,
        qualificationId: item.id,
        reason: reason,
      );
      ref.read(adminApprovalProvider(ApprovalType.qualification).notifier).removeItem(item.id);
      ref.invalidate(adminPendingCountsProvider);
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminQualifications_rejectSuccess(
          (item.data['name'] ?? '').toString(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminQualifications_rejectError);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  Future<void> _approveEarlyPayment(ApprovalItem item) async {
    if (_processingIds.contains(item.id)) return;
    setState(() => _processingIds.add(item.id));

    try {
      await _paymentService.approveEarlyPayment(item.id);
      await _notificationService.createNotification(
        targetUid: item.workerUid,
        title: context.l10n.adminEarlyPayments_notifyApprovedTitle,
        body: context.l10n.adminEarlyPayments_notifyApprovedBody,
        type: 'early_payment',
      );
      ref.read(adminApprovalProvider(ApprovalType.earlyPayment).notifier).removeItem(item.id);
      ref.invalidate(adminPendingCountsProvider);
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminEarlyPayments_snackApproved);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminEarlyPayments_snackApproveFailed);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  Future<void> _rejectEarlyPayment(ApprovalItem item) async {
    final reason = await showRejectReasonDialog(context);
    if (reason == null) return;

    if (_processingIds.contains(item.id)) return;
    setState(() => _processingIds.add(item.id));

    try {
      await _paymentService.rejectEarlyPayment(
        requestId: item.id,
        reason: reason,
      );
      await _notificationService.createNotification(
        targetUid: item.workerUid,
        title: context.l10n.adminEarlyPayments_notifyRejectedTitle,
        body: context.l10n.adminEarlyPayments_notifyRejectedBody(reason),
        type: 'early_payment',
      );
      ref.read(adminApprovalProvider(ApprovalType.earlyPayment).notifier).removeItem(item.id);
      ref.invalidate(adminPendingCountsProvider);
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminEarlyPayments_snackRejected);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminEarlyPayments_snackRejectFailed);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  Future<void> _approveVerification(ApprovalItem item) async {
    final confirmed = await ErrorHandler.showConfirmDialog(
      context,
      title: context.l10n.adminIdentityVerification_approveTitle,
      message: context.l10n.adminIdentityVerification_approveConfirm,
    );
    if (confirmed != true) return;

    if (_processingIds.contains(item.id)) return;
    setState(() => _processingIds.add(item.id));

    try {
      await _ekycService.approveVerification(item.workerUid, _myUid);
      ref.read(adminApprovalProvider(ApprovalType.verification).notifier).removeItem(item.id);
      ref.invalidate(adminPendingCountsProvider);
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminIdentityVerification_approved);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminIdentityVerification_approveFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  Future<void> _rejectVerification(ApprovalItem item) async {
    final reason = await showRejectReasonDialog(context);
    if (reason == null) return;

    if (_processingIds.contains(item.id)) return;
    setState(() => _processingIds.add(item.id));

    try {
      await _ekycService.rejectVerification(item.workerUid, _myUid, reason);
      ref.read(adminApprovalProvider(ApprovalType.verification).notifier).removeItem(item.id);
      ref.invalidate(adminPendingCountsProvider);
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminIdentityVerification_rejected);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminIdentityVerification_rejectFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  void _showPhotoDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            AppCachedImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 400,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  /// 写真サムネイル（タップで拡大表示）
  Widget _buildPhotoThumbnail({required String url, required String label}) {
    return GestureDetector(
      onTap: () => _showPhotoDialog(url, label),
      child: Column(
        children: [
          AppCachedImage(
            imageUrl: url,
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
            borderRadius: 8,
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: context.appColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCounts = ref.watch(adminPendingCountsProvider);

    return Column(
      children: [
        // タブ切替
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0),
          child: pendingCounts.when(
            loading: () => _buildSegmentedButton(0, 0, 0),
            error: (_, __) => _buildSegmentedButton(0, 0, 0),
            data: (counts) => _buildSegmentedButton(
              counts.pendingQualifications,
              counts.pendingEarlyPayments,
              counts.pendingVerifications,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // リスト
        Expanded(child: _buildApprovalList()),
      ],
    );
  }

  Widget _buildSegmentedButton(int qualCount, int payCount, int verifyCount) {
    return SegmentedButton<ApprovalType>(
      segments: [
        ButtonSegment(
          value: ApprovalType.qualification,
          label: Text(
            '${context.l10n.adminApproval_qualifications}${qualCount > 0 ? ' ($qualCount)' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
          icon: const Icon(Icons.workspace_premium, size: 16),
        ),
        ButtonSegment(
          value: ApprovalType.earlyPayment,
          label: Text(
            '${context.l10n.adminApproval_earlyPayments}${payCount > 0 ? ' ($payCount)' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
          icon: const Icon(Icons.flash_on, size: 16),
        ),
        ButtonSegment(
          value: ApprovalType.verification,
          label: Text(
            '${context.l10n.adminApproval_verification}${verifyCount > 0 ? ' ($verifyCount)' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
          icon: const Icon(Icons.verified_user, size: 16),
        ),
      ],
      selected: {_selectedType},
      onSelectionChanged: (selected) {
        setState(() => _selectedType = selected.first);
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildApprovalList() {
    final asyncState = ref.watch(adminApprovalProvider(_selectedType));

    return asyncState.when(
      loading: () => SkeletonList(itemBuilder: (_) => const SkeletonApprovalCard()),
      error: (error, _) => Center(child: Text(context.l10n.common_loadError('$error'))),
      data: (state) {
        // ワーカー名の解決（build外で非同期実行）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _resolveWorkerNames(state.items);
        });

        if (state.items.isEmpty) {
          return EmptyState(
            icon: _iconForType(_selectedType),
            title: context.l10n.adminApproval_emptyTitle,
            description: context.l10n.adminApproval_emptyDescription,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(adminApprovalProvider(_selectedType).notifier).refresh(),
          child: ListView.separated(
            padding: AppSpacing.listInsets,
            itemCount: state.items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == state.items.length) {
                return LoadMoreButton(
                  hasMore: state.hasMore,
                  isLoading: state.isLoadingMore,
                  onPressed: () => ref.read(adminApprovalProvider(_selectedType).notifier).loadMore(),
                );
              }

              final item = state.items[index];
              final workerName = _resolvedNames[item.workerUid] ?? '';

              return StaggeredFadeSlide(
                index: index,
                child: _buildCard(item, workerName),
              );
            },
          ),
        );
      },
    );
  }

  IconData _iconForType(ApprovalType type) {
    switch (type) {
      case ApprovalType.qualification:
        return Icons.workspace_premium;
      case ApprovalType.earlyPayment:
        return Icons.flash_on;
      case ApprovalType.verification:
        return Icons.verified_user;
    }
  }

  Widget _buildCard(ApprovalItem item, String workerName) {
    switch (item.type) {
      case ApprovalType.qualification:
        return _buildQualificationCard(item, workerName);
      case ApprovalType.earlyPayment:
        return _buildEarlyPaymentCard(item, workerName);
      case ApprovalType.verification:
        return _buildVerificationCard(item, workerName);
    }
  }

  Widget _buildQualificationCard(ApprovalItem item, String workerName) {
    final qualName = (item.data['name'] ?? '').toString();
    final category = (item.data['category'] ?? '').toString();
    final certPhotoUrl = (item.data['certPhotoUrl'] ?? '').toString();

    return AdminApprovalCard(
      workerName: workerName,
      workerUid: item.workerUid,
      isProcessing: _processingIds.contains(item.id),
      statusBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.appColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
        child: Text(
          context.l10n.adminQualifications_pendingApproval,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.appColors.warning,
          ),
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appColors.primaryPale.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium, size: 18, color: context.appColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        qualName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.adminQualifications_category(category),
                    style: TextStyle(fontSize: 12, color: context.appColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (certPhotoUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCachedImage(
              imageUrl: certPhotoUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: 10,
            ),
          ],
        ],
      ),
      onApprove: () => _approveQualification(item),
      onReject: () => _rejectQualification(item),
    );
  }

  Widget _buildEarlyPaymentCard(ApprovalItem item, String workerName) {
    final month = (item.data['month'] ?? '').toString();
    final requestedAmount = (item.data['requestedAmount'] as num?)?.toInt() ?? 0;
    final fee = (item.data['earlyPaymentFee'] as num?)?.toInt() ?? 0;
    final payout = (item.data['payoutAmount'] as num?)?.toInt() ?? 0;

    String dateStr = '';
    if (item.createdAt != null) {
      final d = item.createdAt!;
      dateStr = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    return AdminApprovalCard(
      workerName: workerName,
      workerUid: item.workerUid,
      isProcessing: _processingIds.contains(item.id),
      statusBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appColors.chipUnselected,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildAmountRow(context.l10n.adminEarlyPayments_targetMonth, month, isBold: false),
                const SizedBox(height: 8),
                _buildAmountRow(context.l10n.adminEarlyPayments_requestedAmount, CurrencyUtils.formatYen(requestedAmount), isBold: true),
                const SizedBox(height: 4),
                _buildAmountRow(context.l10n.adminEarlyPayments_fee, '-${CurrencyUtils.formatYen(fee)}', isError: true),
                const Divider(height: 16),
                _buildAmountRow(context.l10n.adminEarlyPayments_payoutAmount, CurrencyUtils.formatYen(payout), isPrimary: true, isBold: true),
              ],
            ),
          ),
          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.adminEarlyPayments_requestDate(dateStr),
              style: TextStyle(fontSize: 11, color: context.appColors.textHint),
            ),
          ],
        ],
      ),
      onApprove: () => _approveEarlyPayment(item),
      onReject: () => _rejectEarlyPayment(item),
    );
  }

  Widget _buildAmountRow(String label, String value, {bool isBold = false, bool isError = false, bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: context.appColors.textSecondary,
        )),
        Text(value, style: TextStyle(
          fontSize: isPrimary ? 18 : isBold ? 16 : 14,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          color: isError ? context.appColors.error : isPrimary ? context.appColors.primary : context.appColors.textPrimary,
        )),
      ],
    );
  }

  Widget _buildVerificationCard(ApprovalItem item, String workerName) {
    final model = IdentityVerificationModel.fromMap(item.data);

    String dateStr = '';
    if (item.createdAt != null) {
      final d = item.createdAt!;
      dateStr = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    return AdminApprovalCard(
      workerName: workerName,
      workerUid: item.workerUid,
      isProcessing: _processingIds.contains(item.id),
      statusBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.appColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
        child: Text(
          context.l10n.adminApproval_pendingReview,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.appColors.info,
          ),
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge, size: 16, color: context.appColors.textHint),
              const SizedBox(width: 4),
              Text(
                model.documentTypeLabel,
                style: TextStyle(fontSize: 13, color: context.appColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 16, color: context.appColors.textHint),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: context.appColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 写真グリッド（表面 / 裏面 / 自撮り）
          Row(
            children: [
              Expanded(
                child: _buildPhotoThumbnail(
                  url: model.idPhotoUrl,
                  label: context.l10n.adminIdentityVerification_idDocumentPhoto,
                ),
              ),
              if (model.idPhotoBackUrl != null && model.idPhotoBackUrl!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoThumbnail(
                    url: model.idPhotoBackUrl!,
                    label: context.l10n.identityVerification_idDocumentBack,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _buildPhotoThumbnail(
                  url: model.selfieUrl,
                  label: context.l10n.adminIdentityVerification_selfiePhoto,
                ),
              ),
            ],
          ),
        ],
      ),
      onApprove: () => _approveVerification(item),
      onReject: () => _rejectVerification(item),
    );
  }
}
