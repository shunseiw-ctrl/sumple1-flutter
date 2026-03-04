import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/providers/admin_jobs_provider.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/utils/currency_utils.dart';
import 'package:sumple1/presentation/widgets/admin_search_bar.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'package:sumple1/presentation/widgets/load_more_button.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';

class AdminJobManagementTab extends ConsumerStatefulWidget {
  const AdminJobManagementTab({super.key});

  @override
  ConsumerState<AdminJobManagementTab> createState() =>
      _AdminJobManagementTabState();
}

class _AdminJobManagementTabState extends ConsumerState<AdminJobManagementTab>
    with TickerProviderStateMixin {
  /// 0 = 案件一覧, 1 = 全応募ステータス
  int _viewIndex = 0;

  late final TabController _applicationTabController;

  static const _applicationStatusKeys = [
    'all',
    'applied',
    'assigned',
    'in_progress',
    'completed',
    'inspection',
    'fixing',
    'done',
  ];

  @override
  void initState() {
    super.initState();
    _applicationTabController =
        TabController(length: _applicationStatusKeys.length, vsync: this);
    _applicationTabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _applicationTabController.dispose();
    super.dispose();
  }

  List<JobItem> _applyFilters(AdminListState<JobItem> state) {
    var items = state.items;

    if (state.filterStatus != 'all') {
      items = items.where((item) => item.status == state.filterStatus).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      items = items.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Column(
        children: [
          // ビュー切り替えセグメント
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(context.l10n.adminJob_viewJobs),
                    icon: const Icon(Icons.work_outline, size: 18),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(context.l10n.adminJob_viewApplications),
                    icon: const Icon(Icons.people_outline, size: 18),
                  ),
                ],
                selected: {_viewIndex},
                onSelectionChanged: (set) => setState(() => _viewIndex = set.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor:
                      context.appColors.primary.withValues(alpha: 0.12),
                  selectedForegroundColor: context.appColors.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: _viewIndex == 0
                ? _buildJobsListView()
                : _buildApplicationsStatusView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.postJob),
        backgroundColor: context.appColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.adminJobManagement_postJob,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ────────────────────────────────────
  // ビュー1: 案件一覧
  // ────────────────────────────────────
  Widget _buildJobsListView() {
    final asyncState = ref.watch(adminJobsProvider);

    return asyncState.when(
      loading: () => SkeletonList(itemBuilder: (_) => const SkeletonWorkCard()),
      error: (error, _) => ErrorRetryWidget.general(
        onRetry: () => ref.read(adminJobsProvider.notifier).refresh(),
        message: context.l10n.common_loadError('$error'),
      ),
      data: (state) {
        final filteredItems = _applyFilters(state);

        // サマリー統計の計算
        final totalCount = state.items.length;
        final activeCount =
            state.items.where((j) => j.status == 'active').length;
        final completedCount =
            state.items.where((j) => j.status == 'completed').length;

        return Column(
          children: [
            // 検索バー
            AdminSearchBar(
              hintText: context.l10n.adminJobManagement_searchHint,
              onChanged: (query) {
                ref.read(adminJobsProvider.notifier).setSearchQuery(query);
              },
            ),
            // サマリー統計カード
            _SummaryStats(
              items: [
                _StatItem(
                  label: context.l10n.adminJob_summaryTotal(totalCount.toString()),
                  color: context.appColors.textPrimary,
                  isSelected: state.filterStatus == 'all',
                  onTap: () =>
                      ref.read(adminJobsProvider.notifier).setFilter('all'),
                ),
                _StatItem(
                  label: context.l10n.adminJob_summaryActive(activeCount.toString()),
                  color: context.appColors.success,
                  isSelected: state.filterStatus == 'active',
                  onTap: () =>
                      ref.read(adminJobsProvider.notifier).setFilter('active'),
                ),
                _StatItem(
                  label: context.l10n.adminJob_summaryCompleted(completedCount.toString()),
                  color: context.appColors.info,
                  isSelected: state.filterStatus == 'completed',
                  onTap: () => ref
                      .read(adminJobsProvider.notifier)
                      .setFilter('completed'),
                ),
              ],
            ),
            // リスト
            Expanded(
              child: filteredItems.isEmpty
                  ? EmptyState(
                      icon: Icons.work_off_outlined,
                      title: context.l10n.adminJobManagement_noJobs,
                      description: context.l10n.adminJobManagement_postHint,
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(adminJobsProvider.notifier).refresh(),
                      color: context.appColors.primary,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pagePadding,
                            AppSpacing.sm,
                            AppSpacing.pagePadding,
                            80),
                        itemCount: filteredItems.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index == filteredItems.length) {
                            return LoadMoreButton(
                              hasMore: state.hasMore,
                              isLoading: state.isLoadingMore,
                              onPressed: () => ref
                                  .read(adminJobsProvider.notifier)
                                  .loadMore(),
                            );
                          }
                          final job = filteredItems[index];
                          return StaggeredFadeSlide(
                            index: index,
                            child: _JobCard(job: job),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────
  // ビュー2: 全応募ステータス（WorkPage風）
  // ────────────────────────────────────
  Widget _buildApplicationsStatusView() {
    final tabIndex = _applicationTabController.index
        .clamp(0, _applicationStatusKeys.length - 1);
    final selectedKey = _applicationStatusKeys[tabIndex];

    return Column(
      children: [
        Material(
          color: context.appColors.surface,
          elevation: 0,
          child: TabBar(
            controller: _applicationTabController,
            isScrollable: true,
            labelColor: context.appColors.primary,
            unselectedLabelColor: context.appColors.textSecondary,
            indicatorColor: context.appColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.labelMedium
                .copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppTextStyles.labelMedium,
            tabs: [
              Tab(text: context.l10n.adminApplicants_filterAll),
              Tab(text: context.l10n.adminApplicants_filterApplied),
              Tab(text: context.l10n.adminApplicants_filterAssigned),
              Tab(text: context.l10n.adminApplicants_filterInProgress),
              Tab(text: context.l10n.statusBadge_completed),
              Tab(text: context.l10n.statusBadge_inspection),
              Tab(text: context.l10n.statusBadge_fixing),
              Tab(text: context.l10n.adminApplicants_filterDone),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .orderBy('createdAt', descending: true)
                .limit(200)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return ErrorRetryWidget.general(
                  onRetry: () => setState(() {}),
                  message: context.l10n.common_loadError('${snap.error}'),
                );
              }
              if (!snap.hasData) {
                return SkeletonList(
                    itemBuilder: (_) => const SkeletonWorkCard());
              }

              final allDocs = snap.data!.docs.toList();

              List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered;
              if (selectedKey == 'all') {
                filtered = allDocs;
              } else {
                filtered = allDocs.where((d) {
                  final status =
                      (d.data()['status'] ?? 'applied').toString();
                  return status == selectedKey;
                }).toList();
              }

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.inbox_outlined,
                  title: context.l10n.adminApplicants_noApplicantsYet,
                  description: '',
                );
              }

              // 「全応募」タブの場合: ステータスグループ表示
              if (selectedKey == 'all') {
                final applied = filtered
                    .where((d) =>
                        (d.data()['status'] ?? 'applied').toString() ==
                        'applied')
                    .toList();
                final assigned = filtered
                    .where((d) {
                      final s = (d.data()['status'] ?? '').toString();
                      return s == 'assigned' || s == 'in_progress';
                    })
                    .toList();
                final completed = filtered
                    .where((d) {
                      final s = (d.data()['status'] ?? '').toString();
                      return s == 'completed' ||
                          s == 'inspection' ||
                          s == 'fixing' ||
                          s == 'done';
                    })
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: context.appColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.md,
                        AppSpacing.pagePadding,
                        AppSpacing.xl),
                    children: [
                      _AdminStatusGroup(
                        title: context.l10n.adminApplicants_filterApplied,
                        icon: Icons.hourglass_empty,
                        color: context.appColors.warning,
                        count: applied.length,
                        docs: applied,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _AdminStatusGroup(
                        title: context.l10n.adminApplicants_summaryAssigned(
                            assigned.length.toString()),
                        icon: Icons.check_circle_outline,
                        color: context.appColors.primary,
                        count: assigned.length,
                        docs: assigned,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _AdminStatusGroup(
                        title: context.l10n.adminApplicants_summaryDone(
                            completed.length.toString()),
                        icon: Icons.done_all,
                        color: context.appColors.success,
                        count: completed.length,
                        docs: completed,
                      ),
                    ],
                  ),
                );
              }

              // 個別タブ: フィルタ済みリスト
              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                color: context.appColors.primary,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding,
                      AppSpacing.md, AppSpacing.pagePadding, AppSpacing.xl),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    return StaggeredFadeSlide(
                      index: i,
                      child: _ApplicationCard(doc: filtered[i]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────
// サマリー統計バー
// ────────────────────────────────────
class _StatItem {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatItem({
    required this.label,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });
}

class _SummaryStats extends StatelessWidget {
  final List<_StatItem> items;
  const _SummaryStats({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding, vertical: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: item.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.isSelected
                        ? item.color.withValues(alpha: 0.12)
                        : context.appColors.chipUnselected,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.chipRadius),
                    border: item.isSelected
                        ? Border.all(color: item.color, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    item.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: item.isSelected
                          ? item.color
                          : context.appColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ────────────────────────────────────
// 案件カード（コンパクト版）
// ────────────────────────────────────
class _JobCard extends StatelessWidget {
  final JobItem job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.xs),
        title: Row(
          children: [
            Expanded(
              child: Text(
                job.title.isNotEmpty
                    ? job.title
                    : context.l10n.adminJobManagement_noTitle,
                style: AppTextStyles.labelLarge
                    .copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              CurrencyUtils.formatYen(job.price),
              style: AppTextStyles.labelLarge
                  .copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            children: [
              StatusBadge.fromStatus(context, job.status),
              if (job.date.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.event, size: 12, color: context.appColors.textHint),
                const SizedBox(width: 2),
                Text(job.date, style: AppTextStyles.caption),
              ],
              if (job.location.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.place_outlined,
                    size: 12, color: context.appColors.textHint),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(job.location,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
              if (job.applicantCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.people,
                    size: 12, color: context.appColors.primary),
                const SizedBox(width: 2),
                Text(
                  context.l10n
                      .adminJobManagement_applicantCount(job.applicantCount.toString()),
                  style: AppTextStyles.caption.copyWith(
                    color: context.appColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right,
            size: 20, color: context.appColors.textHint),
        onTap: () {
          context.push(RoutePaths.jobDetailPath(job.id), extra: {
            'title': job.title,
            'location': job.location,
            'price': job.price,
            'date': job.date,
            'status': job.status,
          });
        },
      ),
    );
  }
}

// ────────────────────────────────────
// 全応募ステータスのグループ表示（WorkPage _StatusGroup風）
// ────────────────────────────────────
class _AdminStatusGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _AdminStatusGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.docs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title,
                  style: AppTextStyles.labelLarge
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Text('$count',
                  style: AppTextStyles.badgeText.copyWith(color: color)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md, horizontal: AppSpacing.xs),
            child: Text(context.l10n.adminApplicants_noApplicantsYet,
                style: AppTextStyles.bodySmall),
          )
        else
          ...docs.map((appDoc) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ApplicationCard(doc: appDoc),
              )),
      ],
    );
  }
}

// ────────────────────────────────────
// 応募カード（全応募ステータスビュー用）
// ────────────────────────────────────
class _ApplicationCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ApplicationCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final titleSnap =
        (data['jobTitleSnapshot'] ?? data['projectNameSnapshot'] ?? '')
            .toString();
    final statusKey = (data['status'] ?? 'applied').toString();
    final locationSnap = (data['locationSnapshot'] ?? '').toString();
    final dateSnap = (data['dateSnapshot'] ?? '').toString();
    final workerName = (data['workerNameSnapshot'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.xs),
        title: Text(
          titleSnap.isNotEmpty ? titleSnap : context.l10n.common_job,
          style: AppTextStyles.labelLarge
              .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            children: [
              StatusBadge.fromStatus(context, statusKey),
              if (workerName.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(workerName,
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
              if (dateSnap.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(dateSnap, style: AppTextStyles.caption),
              ],
              if (locationSnap.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.place_outlined,
                    size: 12, color: context.appColors.textHint),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(locationSnap,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => context.push(RoutePaths.workDetailPath(doc.id)),
      ),
    );
  }
}
