import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
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
        title: const Text('本人確認承認'),
        content: const Text('この本人確認を承認しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('承認する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _ekycService.approveVerification(uid, _myUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('本人確認を承認しました')),
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

  Future<void> _reject(String uid) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('本人確認却下'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('却下理由を入力してください'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '却下理由（必須）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('却下理由を入力してください')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('却下する'),
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
          const SnackBar(content: Text('本人確認を却下しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('却下に失敗しました: $e')),
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
      appBar: AppBar(title: const Text('本人確認レビュー')),
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
                child: Text('読み込みエラー: ${snap.error}'),
              );
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 48, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text(
                          '未処理の本人確認申請はありません',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
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
                  onTapIdPhoto: () => _showPhotoDialog(model.idPhotoUrl, '身分証明書'),
                  onTapSelfie: () => _showPhotoDialog(model.selfieUrl, '顔写真'),
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
  final VoidCallback onTapSelfie;

  const _VerificationCard({
    required this.model,
    required this.onApprove,
    required this.onReject,
    required this.onTapIdPhoto,
    required this.onTapSelfie,
  });

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ワーカー情報
          _WorkerInfo(uid: model.uid),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.badge, size: 16, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                model.documentTypeLabel,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 16, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 写真表示
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTapIdPhoto,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppCachedImage(
                          imageUrl: model.idPhotoUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('身分証明書', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTapSelfie,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppCachedImage(
                          imageUrl: model.selfieUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('顔写真', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // アクションボタン
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
                  label: const Text('承認'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
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
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.ruriPale,
              child: Icon(Icons.person, color: AppColors.ruri, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
