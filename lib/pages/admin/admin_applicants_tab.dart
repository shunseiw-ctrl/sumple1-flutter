import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/providers/admin_applicants_provider.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';
import 'package:sumple1/presentation/widgets/admin_search_bar.dart';
import 'package:sumple1/presentation/widgets/admin_filter_chips.dart';
import 'package:sumple1/presentation/widgets/load_more_button.dart';
import 'package:sumple1/presentation/widgets/rating_stars_display.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';
import 'package:sumple1/core/services/quality_score_service.dart';

class AdminApplicantsTab extends ConsumerStatefulWidget {
  const AdminApplicantsTab({super.key});

  @override
  ConsumerState<AdminApplicantsTab> createState() => _AdminApplicantsTabState();
}

class _AdminApplicantsTabState extends ConsumerState<AdminApplicantsTab> {
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

  List<ApplicantItem> _applyFilters(AdminListState<ApplicantItem> state) {
    var items = state.items;

    // ステータスフィルタ
    if (state.filterStatus != 'all') {
      items = items.where((item) {
        if (state.filterStatus == 'done') {
          return item.status == 'completed' ||
              item.status == 'inspection' ||
              item.status == 'fixing' ||
              item.status == 'done';
        }
        return item.status == state.filterStatus;
      }).toList();
    }

    // 検索クエリ（ワーカー名 or 案件名）
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      items = items.where((item) {
        return item.jobTitle.toLowerCase().contains(q) ||
            item.workerName.toLowerCase().contains(q);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminApplicantsProvider);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('読み込みエラー: $error')),
      data: (state) {
        final filteredItems = _applyFilters(state);

        return Column(
          children: [
            AdminFilterChips(
              selectedKey: state.filterStatus,
              options: const {
                'all': 'すべて',
                'applied': '応募中',
                'assigned': '着工前',
                'in_progress': '着工中',
                'done': '完了',
              },
              onSelected: (key) {
                ref.read(adminApplicantsProvider.notifier).setFilter(key);
              },
            ),
            AdminSearchBar(
              hintText: 'ワーカー名・案件名で検索',
              onChanged: (query) {
                ref.read(adminApplicantsProvider.notifier).setSearchQuery(query);
              },
            ),
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text(
                            state.filterStatus == 'all' ? '応募者はまだいません' : '${StatusBadge.labelFor(state.filterStatus)}の応募はありません',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filteredItems.length + 1, // +1 for LoadMore
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == filteredItems.length) {
                          return LoadMoreButton(
                            hasMore: state.hasMore,
                            isLoading: state.isLoadingMore,
                            onPressed: () {
                              ref.read(adminApplicantsProvider.notifier).loadMore();
                            },
                          );
                        }

                        final item = filteredItems[index];
                        return _ApplicantCard(
                          item: item,
                          onUpdateStatus: _updateStatus,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicantItem item;
  final Future<void> Function(String appId, String newStatus, String jobTitle) onUpdateStatus;

  const _ApplicantCard({
    required this.item,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    if (item.createdAt != null) {
      final d = item.createdAt!;
      dateStr = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          context.push(RoutePaths.workDetailPath(item.id));
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
                        Text(item.jobTitle,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        if (item.applicantUid.isNotEmpty)
                          _WorkerInfoRow(
                            applicantUid: item.applicantUid,
                            dateStr: dateStr,
                          ),
                        if (item.applicantUid.isEmpty)
                          Row(
                            children: [
                              Text('UID: ${item.applicantUid.length > 8 ? '${item.applicantUid.substring(0, 8)}...' : item.applicantUid}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                              if (dateStr.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: StatusBadge.colorFor(item.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(StatusBadge.labelFor(item.status),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: StatusBadge.colorFor(item.status))),
                  ),
                ],
              ),
              if (item.status == 'applied') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onUpdateStatus(item.id, 'rejected', item.jobTitle),
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
                        onPressed: () => onUpdateStatus(item.id, 'assigned', item.jobTitle),
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
              if (item.status == 'assigned') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => onUpdateStatus(item.id, 'in_progress', item.jobTitle),
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
              if (item.status == 'in_progress') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => onUpdateStatus(item.id, 'completed', item.jobTitle),
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
  }
}

class _WorkerInfoRow extends StatelessWidget {
  final String applicantUid;
  final String dateStr;

  const _WorkerInfoRow({
    required this.applicantUid,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('profiles').doc(applicantUid).snapshots(),
      builder: (context, profileSnap) {
        final profileData = profileSnap.data?.data();
        final familyName = (profileData?['familyName'] ?? '').toString().trim();
        final givenName = (profileData?['givenName'] ?? '').toString().trim();
        final displayName = (profileData?['displayName'] ?? '').toString().trim();
        final workerName = displayName.isNotEmpty
            ? displayName
            : (familyName.isNotEmpty || givenName.isNotEmpty)
                ? '$familyName $givenName'.trim()
                : '';
        final avg = (profileData?['ratingAverage'] ?? 0).toDouble();
        final rCount = (profileData?['ratingCount'] ?? 0) as int;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (workerName.isNotEmpty) ...[
                  Text(workerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                ],
                Text('UID: ${applicantUid.length > 8 ? '${applicantUid.substring(0, 8)}...' : applicantUid}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ],
            ),
            if (rCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    RatingStarsDisplay(
                      average: avg,
                      count: rCount,
                      starSize: 14,
                      fontSize: 11,
                    ),
                    const SizedBox(width: 6),
                    _QualityScoreBadge(uid: applicantUid),
                  ],
                ),
              ),
            if (rCount == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _QualityScoreBadge(uid: applicantUid),
              ),
          ],
        );
      },
    );
  }
}

class _QualityScoreBadge extends StatelessWidget {
  final String uid;
  const _QualityScoreBadge({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<WorkerQualityScore>(
      future: QualityScoreService().calculateScore(uid),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final score = snap.data!.overallScore;
        final Color bgColor;
        final Color textColor;
        if (score >= 4.0) {
          bgColor = AppColors.success.withValues(alpha: 0.15);
          textColor = AppColors.success;
        } else if (score >= 3.0) {
          bgColor = AppColors.warning.withValues(alpha: 0.15);
          textColor = AppColors.warning;
        } else {
          bgColor = AppColors.error.withValues(alpha: 0.15);
          textColor = AppColors.error;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '品質: ${score.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        );
      },
    );
  }
}
