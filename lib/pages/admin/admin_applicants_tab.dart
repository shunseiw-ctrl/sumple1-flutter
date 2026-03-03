import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
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
        title: Text(context.l10n.adminApplicants_changeStatusTitle),
        content: Text(context.l10n.adminApplicants_changeStatusConfirm(jobTitle, StatusBadge.labelFor(newStatus))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.common_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.adminApplicants_changeButton),
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
          'title': context.l10n.adminApplicants_statusUpdateNotifTitle,
          'body': context.l10n.adminApplicants_statusUpdateNotifBody(jobTitle, StatusBadge.labelFor(newStatus)),
          'type': 'status_update',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminApplicants_statusChanged(jobTitle, StatusBadge.labelFor(newStatus)))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminApplicants_changeFailed('$e'))),
        );
      }
    }
  }

  Future<void> _bulkApprove(List<ApplicantItem> items) async {
    final appliedItems = items.where((i) => i.status == 'applied').toList();
    if (appliedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminApplicants_bulkApproveTitle),
        content: Text(context.l10n.adminApplicants_bulkApproveConfirm(appliedItems.length.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.adminApplicants_bulkApproveButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in appliedItems) {
        final ref = FirebaseFirestore.instance.collection('applications').doc(item.id);
        batch.update(ref, {
          'status': 'assigned',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminApplicants_bulkApproved(appliedItems.length.toString()))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminApplicants_bulkApproveFailed('$e'))),
        );
      }
    }
  }

  List<ApplicantItem> _applyFilters(AdminListState<ApplicantItem> state) {
    var items = state.items;

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
      error: (error, _) => Center(child: Text(context.l10n.common_loadError('$error'))),
      data: (state) {
        final filteredItems = _applyFilters(state);

        return Column(
          children: [
            AdminFilterChips(
              selectedKey: state.filterStatus,
              options: {
                'all': context.l10n.adminApplicants_filterAll,
                'applied': context.l10n.adminApplicants_filterApplied,
                'assigned': context.l10n.adminApplicants_filterAssigned,
                'in_progress': context.l10n.adminApplicants_filterInProgress,
                'done': context.l10n.adminApplicants_filterDone,
              },
              onSelected: (key) {
                ref.read(adminApplicantsProvider.notifier).setFilter(key);
              },
            ),
            AdminSearchBar(
              hintText: context.l10n.adminApplicants_searchHint,
              onChanged: (query) {
                ref.read(adminApplicantsProvider.notifier).setSearchQuery(query);
              },
            ),
            if (state.filterStatus == 'applied' && filteredItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _bulkApprove(filteredItems),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(context.l10n.adminApplicants_bulkApproveCount(filteredItems.length.toString())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.success,
                      side: BorderSide(color: context.appColors.success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: context.appColors.textHint),
                          const SizedBox(height: 12),
                          Text(
                            state.filterStatus == 'all' ? context.l10n.adminApplicants_noApplicantsYet : context.l10n.adminApplicants_noApplicantsForStatus(StatusBadge.labelFor(state.filterStatus)),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.appColors.textSecondary),
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
      color: context.appColors.surface,
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
            border: Border.all(color: context.appColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.appColors.primaryPale,
                    child: Icon(Icons.person, color: context.appColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.jobTitle,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.appColors.textPrimary),
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
                                  style: TextStyle(fontSize: 11, color: context.appColors.textHint)),
                              if (dateStr.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(dateStr, style: TextStyle(fontSize: 11, color: context.appColors.textHint)),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: StatusBadge.colorFor(context, item.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(StatusBadge.labelFor(item.status),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: StatusBadge.colorFor(context, item.status))),
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
                        label: Text(context.l10n.common_reject),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.appColors.error,
                          side: BorderSide(color: context.appColors.error),
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
                        label: Text(context.l10n.common_approve),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.success,
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
                    label: Text(context.l10n.adminApplicants_startWork),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.primary,
                      side: BorderSide(color: context.appColors.primary),
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
                    label: Text(context.l10n.adminApplicants_workCompleted),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.success,
                      side: BorderSide(color: context.appColors.success),
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
                  Text(workerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.appColors.textSecondary)),
                  const SizedBox(width: 6),
                ],
                Text('UID: ${applicantUid.length > 8 ? '${applicantUid.substring(0, 8)}...' : applicantUid}',
                    style: TextStyle(fontSize: 11, color: context.appColors.textHint)),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(dateStr, style: TextStyle(fontSize: 11, color: context.appColors.textHint)),
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
          bgColor = context.appColors.success.withValues(alpha: 0.15);
          textColor = context.appColors.success;
        } else if (score >= 3.0) {
          bgColor = context.appColors.warning.withValues(alpha: 0.15);
          textColor = context.appColors.warning;
        } else {
          bgColor = context.appColors.error.withValues(alpha: 0.15);
          textColor = context.appColors.error;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            context.l10n.adminApplicants_qualityScore(score.toStringAsFixed(1)),
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
