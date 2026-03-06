import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';

class AdminIdentityVerificationPage extends StatefulWidget {
  final ManualEkycService? ekycService;
  const AdminIdentityVerificationPage({super.key, this.ekycService});

  @override
  State<AdminIdentityVerificationPage> createState() =>
      _AdminIdentityVerificationPageState();
}

class _AdminIdentityVerificationPageState
    extends State<AdminIdentityVerificationPage> {
  late final ManualEkycService _ekycService;
  Key _refreshKey = UniqueKey();

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _ekycService = widget.ekycService ?? ManualEkycService();
    AnalyticsService.logScreenView('admin_identity_verification');
  }

  Future<void> _approve(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminIdentityVerification_approveTitle),
        content: Text(context.l10n.adminIdentityVerification_approveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.adminIdentityVerification_approveButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _ekycService.approveVerification(uid, _myUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminIdentityVerification_approved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminIdentityVerification_approveFailed('$e'))),
        );
      }
    }
  }

  Future<void> _reject(String uid) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminIdentityVerification_rejectTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.adminIdentityVerification_enterRejectReason),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.l10n.adminIdentityVerification_rejectReasonHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(context.l10n.adminIdentityVerification_enterRejectReason)),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.appColors.error),
            child: Text(context.l10n.adminIdentityVerification_rejectButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _ekycService.rejectVerification(
        uid,
        _myUid,
        reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminIdentityVerification_rejected)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminIdentityVerification_rejectFailed('$e'))),
        );
      }
    } finally {
      reasonController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.adminIdentityVerification_title)),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _refreshKey = UniqueKey());
        },
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: _refreshKey,
          stream: FirebaseFirestore.instance
              .collection('identity_verification')
              .where('status', isEqualTo: 'pending')
              .orderBy('submittedAt', descending: false)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text(context.l10n.common_loadError('${snap.error}')),
              );
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 48, color: context.appColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.adminIdentityVerification_noPendingRequests,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final model = IdentityVerificationModel.fromMap(data);

                return _VerificationCard(
                  model: model,
                  onApprove: () => _approve(model.uid),
                  onReject: () => _reject(model.uid),
                  onTapIdPhoto: () => _showPhotoDialog(
                    model.idPhotoUrl,
                    context.l10n.adminIdentityVerification_idDocumentPhoto,
                  ),
                  onTapIdBackPhoto: model.idPhotoBackUrl != null
                      ? () => _showPhotoDialog(
                            model.idPhotoBackUrl!,
                            context.l10n.adminIdentityVerification_idDocumentBackPhoto,
                          )
                      : null,
                  onTapSelfie: () => _showPhotoDialog(
                    model.selfieUrl,
                    context.l10n.adminIdentityVerification_selfiePhoto,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final IdentityVerificationModel model;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTapIdPhoto;
  final VoidCallback? onTapIdBackPhoto;
  final VoidCallback onTapSelfie;

  const _VerificationCard({
    required this.model,
    required this.onApprove,
    required this.onReject,
    required this.onTapIdPhoto,
    this.onTapIdBackPhoto,
    required this.onTapSelfie,
  });

  Color _scoreColor(BuildContext context, double score) {
    if (score >= 80) return context.appColors.success;
    if (score >= 60) return Colors.orange;
    return context.appColors.error;
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    if (model.submittedAt != null) {
      final d = model.submittedAt!;
      dateStr =
          '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.divider),
        boxShadow: [
          BoxShadow(color: context.appColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkerInfo(uid: model.uid),
          const SizedBox(height: 8),
          // メタ情報行
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
          const SizedBox(height: 8),
          // eKYCバッジ行
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Livenessバッジ
              if (model.livenessVerified)
                Chip(
                  avatar: Icon(Icons.check_circle, size: 16, color: context.appColors.success),
                  label: Text(
                    context.l10n.adminIdentityVerification_livenessVerified,
                    style: const TextStyle(fontSize: 11),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: context.appColors.success.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              // faceMatchScoreバッジ
              if (model.faceMatchScore != null)
                Chip(
                  avatar: Icon(
                    Icons.face,
                    size: 16,
                    color: _scoreColor(context, model.faceMatchScore!),
                  ),
                  label: Text(
                    '${context.l10n.adminIdentityVerification_faceMatchScore}: ${model.faceMatchScore!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _scoreColor(context, model.faceMatchScore!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _scoreColor(context, model.faceMatchScore!).withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 写真3列グリッド（表面/裏面/自撮り）
          Row(
            children: [
              // 表面
              Expanded(
                child: GestureDetector(
                  onTap: onTapIdPhoto,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppCachedImage(
                          imageUrl: model.idPhotoUrl,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.adminIdentityVerification_idDocumentPhoto,
                        style: TextStyle(fontSize: 10, color: context.appColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 裏面
              Expanded(
                child: model.idPhotoBackUrl != null
                    ? GestureDetector(
                        onTap: onTapIdBackPhoto,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppCachedImage(
                                imageUrl: model.idPhotoBackUrl!,
                                height: 80,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.adminIdentityVerification_idDocumentBackPhoto,
                              style: TextStyle(fontSize: 10, color: context.appColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.appColors.chipUnselected,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            context.l10n.adminIdentityVerification_noBackPhoto,
                            style: TextStyle(fontSize: 10, color: context.appColors.textHint),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              // 自撮り
              Expanded(
                child: GestureDetector(
                  onTap: onTapSelfie,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppCachedImage(
                          imageUrl: model.selfieUrl,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.adminIdentityVerification_selfiePhoto,
                        style: TextStyle(fontSize: 10, color: context.appColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 承認/却下ボタン
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(context.l10n.common_reject),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appColors.error,
                    side: BorderSide(color: context.appColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(context.l10n.common_approve),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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

class _WorkerInfo extends StatelessWidget {
  final String uid;
  const _WorkerInfo({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('profiles').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final familyName = (data?['familyName'] ?? '').toString().trim();
        final givenName = (data?['givenName'] ?? '').toString().trim();
        final displayName = (data?['displayName'] ?? '').toString().trim();
        final name = displayName.isNotEmpty
            ? displayName
            : (familyName.isNotEmpty || givenName.isNotEmpty)
                ? '$familyName $givenName'.trim()
                : 'UID: ${uid.length > 8 ? '${uid.substring(0, 8)}...' : uid}';

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: context.appColors.primaryPale,
              child: Icon(Icons.person, color: context.appColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
