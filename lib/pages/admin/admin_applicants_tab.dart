import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/presentation/widgets/rating_stars_display.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';

class AdminApplicantsTab extends StatefulWidget {
  const AdminApplicantsTab({super.key});

  @override
  State<AdminApplicantsTab> createState() => _AdminApplicantsTabState();
}

class _AdminApplicantsTabState extends State<AdminApplicantsTab> {
  String _filterStatus = 'all';

  Future<void> _updateStatus(String appId, String newStatus, String jobTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ステータス変更'),
        content: Text('「$jobTitle」を「${StatusBadge.labelFor(newStatus)}」に変更しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('変更する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('applications').doc(appId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final appDoc = await FirebaseFirestore.instance.collection('applications').doc(appId).get();
      final applicantUid = (appDoc.data()?['applicantUid'] ?? '').toString();
      if (applicantUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'targetUid': applicantUid,
          'title': 'ステータス更新',
          'body': '「$jobTitle」が「${StatusBadge.labelFor(newStatus)}」になりました',
          'type': 'status_update',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$jobTitle」を${StatusBadge.labelFor(newStatus)}に変更しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('変更に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'すべて'),
                _filterChip('applied', '応募中'),
                _filterChip('assigned', '着工前'),
                _filterChip('in_progress', '着工中'),
                _filterChip('done', '完了'),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('読み込みエラー: ${snap.error}'));
              }
              var docs = snap.data?.docs ?? [];

              if (_filterStatus != 'all') {
                docs = docs.where((d) {
                  final s = (d.data()['status'] ?? 'applied').toString();
                  if (_filterStatus == 'done') {
                    return s == 'completed' || s == 'inspection' || s == 'fixing' || s == 'done';
                  }
                  return s == _filterStatus;
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text(
                        _filterStatus == 'all' ? '応募者はまだいません' : '${StatusBadge.labelFor(_filterStatus)}の応募はありません',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final jobTitle = (data['jobTitleSnapshot'] ?? '案件名なし').toString();
                  final status = (data['status'] ?? 'applied').toString();
                  final applicantUid = (data['applicantUid'] ?? '').toString();
                  final createdAt = data['createdAt'];
                  String dateStr = '';
                  if (createdAt is Timestamp) {
                    final d = createdAt.toDate();
                    dateStr = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                  }

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        context.push(RoutePaths.workDetailPath(doc.id));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.ruriPale,
                                  child: Icon(Icons.person, color: AppColors.ruri, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(jobTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text('UID: ${applicantUid.length > 8 ? '${applicantUid.substring(0, 8)}...' : applicantUid}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                          if (dateStr.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                          ],
                                        ],
                                      ),
                                      if (applicantUid.isNotEmpty)
                                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                          stream: FirebaseFirestore.instance.collection('profiles').doc(applicantUid).snapshots(),
                                          builder: (context, profileSnap) {
                                            final profileData = profileSnap.data?.data();
                                            final avg = (profileData?['ratingAverage'] ?? 0).toDouble();
                                            final rCount = (profileData?['ratingCount'] ?? 0) as int;
                                            if (rCount == 0) return const SizedBox.shrink();
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: RatingStarsDisplay(
                                                average: avg,
                                                count: rCount,
                                                starSize: 14,
                                                fontSize: 11,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: StatusBadge.colorFor(status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(StatusBadge.labelFor(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: StatusBadge.colorFor(status))),
                                ),
                              ],
                            ),
                            if (status == 'applied') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _updateStatus(doc.id, 'rejected', jobTitle),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('却下'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _updateStatus(doc.id, 'assigned', jobTitle),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('承認'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (status == 'assigned') ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _updateStatus(doc.id, 'in_progress', jobTitle),
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('着工開始'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ruri,
                                    side: const BorderSide(color: AppColors.ruri),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                            if (status == 'in_progress') ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _updateStatus(doc.id, 'completed', jobTitle),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('施工完了'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.success,
                                    side: const BorderSide(color: AppColors.success),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _filterStatus == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) => setState(() => _filterStatus = key),
        selectedColor: AppColors.ruri,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: AppColors.chipUnselected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }
}
