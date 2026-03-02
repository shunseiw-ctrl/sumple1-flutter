import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
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
        ErrorHandler.showError(context, e, customMessage: '読み込みに失敗しました');
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
    return '名前未設定';
  }

  Future<void> _approve(_PendingQualificationItem item) async {
    try {
      await _qualificationService.approve(
        targetUid: item.workerUid,
        qualificationId: item.qualificationId,
      );
      if (mounted) {
        ErrorHandler.showSuccess(context, '${item.qualificationName} を承認しました');
      }
      await _loadPendingQualifications();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: '承認に失敗しました');
      }
    }
  }

  Future<void> _showRejectDialog(_PendingQualificationItem item) async {
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
        ErrorHandler.showError(context, null, customMessage: '却下理由を入力してください');
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
        ErrorHandler.showSuccess(context, '${item.qualificationName} を却下しました');
      }
      await _loadPendingQualifications();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: '却下に失敗しました');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('資格承認'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingItems.isEmpty
              ? const EmptyState(
                  icon: Icons.workspace_premium,
                  title: '承認待ちの資格はありません',
                  description: 'ワーカーが資格を申請すると、ここに表示されます。',
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
                      item.workerName,
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
                      'UID: ${item.workerUid.length > 8 ? '${item.workerUid.substring(0, 8)}...' : item.workerUid}',
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: const Text(
                  '承認待ち',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
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
              color: AppColors.ruriPale.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium,
                        size: 18, color: AppColors.ruri),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.qualificationName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'カテゴリ: ${item.category}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
                  color: AppColors.chipUnselected,
                  child: const Center(
                    child: Text(
                      '画像を読み込めませんでした',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHint),
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
