import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/qualification_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';

/// 管理者向け資格承認ページ
class AdminQualificationsPage extends StatefulWidget {
  final QualificationService? qualificationService;
  final FirebaseFirestore? firestore;

  const AdminQualificationsPage({
    super.key,
    this.qualificationService,
    this.firestore,
  });

  @override
  State<AdminQualificationsPage> createState() =>
      _AdminQualificationsPageState();
}

class _AdminQualificationsPageState extends State<AdminQualificationsPage> {
  late final QualificationService _qualificationService;
  late final FirebaseFirestore _db;
  bool _isLoading = true;
  List<_PendingQualificationItem> _pendingItems = [];

  @override
  void initState() {
    super.initState();
    _qualificationService = widget.qualificationService ?? QualificationService();
    _db = widget.firestore ?? FirebaseFirestore.instance;
    AnalyticsService.logScreenView('admin_qualifications');
    _loadPendingQualifications();
  }

  Future<void> _loadPendingQualifications() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final profilesSnap =
          await _db.collection('profiles').get();

      final List<_PendingQualificationItem> items = [];

      for (final profileDoc in profilesSnap.docs) {
        final profileData = profileDoc.data();
        final uid = profileDoc.id;
        final displayName = _buildDisplayName(profileData);

        final qualsSnap = await _db
            .collection('profiles')
            .doc(uid)
            .collection('qualifications_v2')
            .where('verificationStatus', isEqualTo: 'pending')
            .get();

        for (final qualDoc in qualsSnap.docs) {
          final qualData = qualDoc.data();
          items.add(_PendingQualificationItem(
            workerUid: uid,
            workerName: displayName,
            qualificationId: qualDoc.id,
            qualificationName: (qualData['name'] ?? '').toString(),
            category: (qualData['category'] ?? '').toString(),
            certPhotoUrl: (qualData['certPhotoUrl'] ?? '').toString(),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _pendingItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminQualifications_loadError);
      }
    }
  }

  String _buildDisplayName(Map<String, dynamic> data) {
    final displayName = (data['displayName'] ?? '').toString().trim();
    if (displayName.isNotEmpty) return displayName;

    final familyName = (data['familyName'] ?? '').toString().trim();
    final givenName = (data['givenName'] ?? '').toString().trim();
    if (familyName.isNotEmpty || givenName.isNotEmpty) {
      return '$familyName $givenName'.trim();
    }
    return '';
  }

  Future<void> _approve(_PendingQualificationItem item) async {
    try {
      await _qualificationService.approve(
        targetUid: item.workerUid,
        qualificationId: item.qualificationId,
      );
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminQualifications_approveSuccess(item.qualificationName));
      }
      await _loadPendingQualifications();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminQualifications_approveError);
      }
    }
  }

  Future<void> _showRejectDialog(_PendingQualificationItem item) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminQualifications_rejectReasonTitle),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            hintText: context.l10n.adminQualifications_rejectReasonHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.adminQualifications_rejectButton),
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
        ErrorHandler.showError(context, null, customMessage: context.l10n.adminQualifications_rejectReasonRequired);
      }
      return;
    }

    try {
      await _qualificationService.reject(
        targetUid: item.workerUid,
        qualificationId: item.qualificationId,
        reason: reason,
      );
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminQualifications_rejectSuccess(item.qualificationName));
      }
      await _loadPendingQualifications();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminQualifications_rejectError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.adminQualifications_title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingItems.isEmpty
              ? EmptyState(
                  icon: Icons.workspace_premium,
                  title: context.l10n.adminQualifications_emptyTitle,
                  description: context.l10n.adminQualifications_emptyDescription,
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingQualifications,
                  child: ListView.separated(
                    padding: AppSpacing.listInsets,
                    itemCount: _pendingItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = _pendingItems[index];
                      return _QualificationCard(
                        item: item,
                        onApprove: () => _approve(item),
                        onReject: () => _showRejectDialog(item),
                      );
                    },
                  ),
                ),
    );
  }
}

class _PendingQualificationItem {
  final String workerUid;
  final String workerName;
  final String qualificationId;
  final String qualificationName;
  final String category;
  final String certPhotoUrl;

  _PendingQualificationItem({
    required this.workerUid,
    required this.workerName,
    required this.qualificationId,
    required this.qualificationName,
    required this.category,
    required this.certPhotoUrl,
  });
}

class _QualificationCard extends StatelessWidget {
  final _PendingQualificationItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _QualificationCard({
    required this.item,
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
                      item.workerName.isNotEmpty ? item.workerName : context.l10n.adminQualifications_noName,
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
                      'UID: ${item.workerUid.length > 8 ? '${item.workerUid.substring(0, 8)}...' : item.workerUid}',
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                    Icon(Icons.workspace_premium,
                        size: 18, color: context.appColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.qualificationName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.adminQualifications_category(item.category),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.certPhotoUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.certPhotoUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: context.appColors.chipUnselected,
                  child: Center(
                    child: Text(
                      context.l10n.adminQualifications_imageLoadError,
                      style: TextStyle(
                          fontSize: 12, color: context.appColors.textHint),
                    ),
                  ),
                ),
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
                  label: Text(context.l10n.adminQualifications_reject),
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
                  label: Text(context.l10n.adminQualifications_approve),
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
