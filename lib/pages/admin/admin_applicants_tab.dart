import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/providers/admin_applicants_provider.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/presentation/widgets/admin_search_bar.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/load_more_button.dart';
import 'package:sumple1/presentation/widgets/rating_stars_display.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';

class AdminApplicantsTab extends ConsumerStatefulWidget {
  const AdminApplicantsTab({super.key});

  @override
  ConsumerState<AdminApplicantsTab> createState() =>
      _AdminApplicantsTabState();
}

class _AdminApplicantsTabState extends ConsumerState<AdminApplicantsTab>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  NotificationService? _notificationServiceInstance;
  NotificationService get _notificationService =>
      _notificationServiceInstance ??= NotificationService();

  static const _statusKeys = [
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
    _tabController =
        TabController(length: _statusKeys.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  Future<void> _updateStatus(
      String appId, String newStatus, String jobTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminApplicants_changeStatusTitle),
        content: Text(context.l10n.adminApplicants_changeStatusConfirm(
            jobTitle, StatusBadge.labelFor(newStatus))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.common_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.adminApplicants_changeButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(appId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final appDoc = await FirebaseFirestore.instance
          .collection('applications')
          .doc(appId)
          .get();
      final applicantUid =
          (appDoc.data()?['applicantUid'] ?? '').toString();
      if (applicantUid.isNotEmpty) {
        await _notificationService.createNotification(
          targetUid: applicantUid,
          title: context.l10n.adminApplicants_statusUpdateNotifTitle,
          body: context.l10n.adminApplicants_statusUpdateNotifBody(
              jobTitle, StatusBadge.labelFor(newStatus)),
          type: 'status_update',
        );
      }

      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminApplicants_statusChanged(
            jobTitle, StatusBadge.labelFor(newStatus)));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n.adminApplicants_changeFailed('$e'));
      }
    }
  }

  Future<void> _bulkApprove(List<ApplicantItem> items) async {
    final appliedItems =
        items.where((i) => i.status == 'applied').toList();
    if (appliedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminApplicants_bulkApproveTitle),
        content: Text(context.l10n.adminApplicants_bulkApproveConfirm(
            appliedItems.length.toString())),
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
      // バッチは500件制限なので分割
      for (var i = 0; i < appliedItems.length; i += 500) {
        final chunk = appliedItems.skip(i).take(500).toList();
        final batch = FirebaseFirestore.instance.batch();
        for (final item in chunk) {
          final ref = FirebaseFirestore.instance
              .collection('applications')
              .doc(item.id);
          batch.update(ref, {
            'status': 'assigned',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminApplicants_bulkApproved(
            appliedItems.length.toString()));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, customMessage: context.l10n
            .adminApplicants_bulkApproveFailed('$e'));
      }
    }
  }

  List<ApplicantItem> _filterByStatus(
      List<ApplicantItem> items, String statusKey) {
    if (statusKey == 'all') return items;
    if (statusKey == 'done') {
      return items
          .where((i) =>
              i.status == 'completed' ||
              i.status == 'inspection' ||
              i.status == 'fixing' ||
              i.status == 'done')
          .toList();
    }
    return items.where((i) => i.status == statusKey).toList();
  }

  List<ApplicantItem> _applySearch(
      List<ApplicantItem> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((item) {
      return item.jobTitle.toLowerCase().contains(q) ||
          item.workerName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminApplicantsProvider);

    return asyncState.when(
      loading: () =>
          SkeletonList(itemBuilder: (_) => const SkeletonWorkCard()),
      error: (error, _) => Center(
          child: Text(context.l10n.common_loadError('$error'))),
      data: (state) {
        final tabIndex =
            _tabController.index.clamp(0, _statusKeys.length - 1);
        final selectedKey = _statusKeys[tabIndex];
        final searchedItems = _applySearch(state.items, state.searchQuery);
        final filteredItems = _filterByStatus(searchedItems, selectedKey);

        // サマリー統計
        final pendingCount =
            state.items.where((i) => i.status == 'applied').length;
        final assignedCount =
            state.items.where((i) => i.status == 'assigned').length;
        final inProgressCount =
            state.items.where((i) => i.status == 'in_progress').length;
        final doneCount = state.items
            .where((i) =>
                i.status == 'completed' ||
                i.status == 'inspection' ||
                i.status == 'fixing' ||
                i.status == 'done')
            .length;

        return Column(
          children: [
            // タブバー
            Material(
              color: context.appColors.surface,
              elevation: 0,
              child: TabBar(
                controller: _tabController,
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
            // サマリー統計
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                  vertical: AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SummaryChip(
                      label: context.l10n.adminApplicants_summaryPending(
                          pendingCount.toString()),
                      color: context.appColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SummaryChip(
                      label: context.l10n.adminApplicants_summaryAssigned(
                          assignedCount.toString()),
                      color: context.appColors.info,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SummaryChip(
                      label: context.l10n
                          .adminApplicants_summaryInProgress(
                              inProgressCount.toString()),
                      color: context.appColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SummaryChip(
                      label: context.l10n.adminApplicants_summaryDone(
                          doneCount.toString()),
                      color: context.appColors.success,
                    ),
                  ],
                ),
              ),
            ),
            // 検索バー
            AdminSearchBar(
              hintText: context.l10n.adminApplicants_searchHint,
              onChanged: (query) {
                ref
                    .read(adminApplicantsProvider.notifier)
                    .setSearchQuery(query);
              },
            ),
            // 「応募中」タブ: 一括承認ボタン
            if (selectedKey == 'applied' && filteredItems.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 0, AppSpacing.pagePadding, AppSpacing.xs),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _bulkApprove(filteredItems),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 18),
                    label: Text(context.l10n
                        .adminApplicants_bulkApproveCount(
                            filteredItems.length.toString())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.success,
                      side: BorderSide(color: context.appColors.success),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            // リスト
            Expanded(
              child: filteredItems.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: selectedKey == 'all'
                          ? context.l10n.adminApplicants_noApplicantsYet
                          : context.l10n
                              .adminApplicants_noApplicantsForStatus(
                                  StatusBadge.labelFor(selectedKey)),
                      description: '',
                    )
                  : selectedKey == 'all'
                      ? _buildStatusGroupView(searchedItems, state)
                      : _buildFlatListView(filteredItems, state),
            ),
          ],
        );
      },
    );
  }

  /// 「全応募」タブ: ステータスグループ表示
  Widget _buildStatusGroupView(
      List<ApplicantItem> items, AdminListState<ApplicantItem> state) {
    final applied =
        items.where((i) => i.status == 'applied').toList();
    final assigned = items
        .where(
            (i) => i.status == 'assigned' || i.status == 'in_progress')
        .toList();
    final completed = items
        .where((i) =>
            i.status == 'completed' ||
            i.status == 'inspection' ||
            i.status == 'fixing' ||
            i.status == 'done')
        .toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminApplicantsProvider.notifier).refresh(),
      color: context.appColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding,
            AppSpacing.sm, AppSpacing.pagePadding, AppSpacing.xl),
        children: [
          _ApplicantStatusGroup(
            title: context.l10n.adminApplicants_filterApplied,
            icon: Icons.hourglass_empty,
            color: context.appColors.warning,
            count: applied.length,
            items: applied,
          ),
          const SizedBox(height: AppSpacing.base),
          _ApplicantStatusGroup(
            title: context.l10n.adminApplicants_filterAssigned,
            icon: Icons.check_circle_outline,
            color: context.appColors.primary,
            count: assigned.length,
            items: assigned,
          ),
          const SizedBox(height: AppSpacing.base),
          _ApplicantStatusGroup(
            title: context.l10n.adminApplicants_filterDone,
            icon: Icons.done_all,
            color: context.appColors.success,
            count: completed.length,
            items: completed,
          ),
          LoadMoreButton(
            hasMore: state.hasMore,
            isLoading: state.isLoadingMore,
            onPressed: () =>
                ref.read(adminApplicantsProvider.notifier).loadMore(),
          ),
        ],
      ),
    );
  }

  /// 個別タブ: フラットリスト表示
  Widget _buildFlatListView(
      List<ApplicantItem> items, AdminListState<ApplicantItem> state) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminApplicantsProvider.notifier).refresh(),
      color: context.appColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding,
            AppSpacing.sm, AppSpacing.pagePadding, AppSpacing.xl),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return LoadMoreButton(
              hasMore: state.hasMore,
              isLoading: state.isLoadingMore,
              onPressed: () => ref
                  .read(adminApplicantsProvider.notifier)
                  .loadMore(),
            );
          }
          final item = items[index];
          return StaggeredFadeSlide(
            index: index,
            child: _ApplicantCard(item: item),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────
// サマリーチップ
// ────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.badgeText.copyWith(color: color),
      ),
    );
  }
}

// ────────────────────────────────────
// ステータスグループ（WorkPage風）
// ────────────────────────────────────
class _ApplicantStatusGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final List<ApplicantItem> items;

  const _ApplicantStatusGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.items,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
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
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md, horizontal: AppSpacing.xs),
            child: Text(context.l10n.adminApplicants_noApplicantsYet,
                style: AppTextStyles.bodySmall),
          )
        else
          ...items.asMap().entries.map((entry) => Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSpacing.sm),
                child: StaggeredFadeSlide(
                  index: entry.key,
                  child: _ApplicantCard(item: entry.value),
                ),
              )),
      ],
    );
  }
}

// ────────────────────────────────────
// 応募者カード（写真・eKYC・資格・完了数・チャット対応）
// ────────────────────────────────────
class _ApplicantCard extends StatelessWidget {
  final ApplicantItem item;
  const _ApplicantCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    if (item.createdAt != null) {
      final d = item.createdAt!;
      dateStr =
          '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    }

    // 「要対応」ハイライト: applied ステータスに左ボーダー
    final isApplied = item.status == 'applied';
    final displayName = item.workerName.isNotEmpty
        ? item.workerName
        : (item.applicantUid.isNotEmpty
            ? 'UID: ${item.applicantUid.substring(0, item.applicantUid.length.clamp(0, 8))}...'
            : '');

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: isApplied
            ? Border(
                left: BorderSide(
                    color: context.appColors.warning, width: 4))
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上段: 案件名 + チャットボタン
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.jobTitle,
                    style: AppTextStyles.labelLarge
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // チャットボタン
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.chat_bubble_outline,
                        size: 18, color: context.appColors.primary),
                    tooltip: context.l10n.adminApplicants_openChat,
                    onPressed: () =>
                        context.push(RoutePaths.chatRoomPath(item.id)),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () =>
                      context.push(RoutePaths.workDetailPath(item.id)),
                  child: Icon(Icons.chevron_right,
                      size: 20, color: context.appColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // 下段: ワーカー情報
            Row(
              children: [
                // プロフィール写真
                GestureDetector(
                  onTap: () {
                    if (item.applicantUid.isNotEmpty) {
                      context.push(RoutePaths.adminWorkerDetailPath(
                          item.applicantUid));
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: context.appColors.primaryPale,
                    backgroundImage: item.photoUrl.isNotEmpty
                        ? NetworkImage(item.photoUrl)
                        : null,
                    child: item.photoUrl.isEmpty
                        ? Icon(Icons.person, size: 18,
                            color: context.appColors.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 名前 + eKYCバッジ
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                if (item.applicantUid.isNotEmpty) {
                                  context.push(RoutePaths.adminWorkerDetailPath(
                                      item.applicantUid));
                                }
                              },
                              child: Text(
                                displayName,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.appColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (item.ekycStatus == 'approved') ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified,
                                size: 14, color: context.appColors.success),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // ステータス + 情報チップ
                      Row(
                        children: [
                          StatusBadge.fromStatus(context, item.status),
                          if (item.verifiedQualificationCount > 0) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _InfoChip(
                              icon: Icons.verified_outlined,
                              label: context.l10n.adminApplicants_qualCount(
                                  item.verifiedQualificationCount.toString()),
                              color: context.appColors.info,
                            ),
                          ],
                          if (item.completedJobCount > 0) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _InfoChip(
                              icon: Icons.check_circle_outline,
                              label: context.l10n.adminApplicants_completedCount(
                                  item.completedJobCount.toString()),
                              color: context.appColors.success,
                            ),
                          ],
                          if (item.ratingCount > 0) ...[
                            const SizedBox(width: AppSpacing.xs),
                            RatingStarsDisplay(
                              average: item.ratingAverage,
                              count: item.ratingCount,
                              starSize: 10,
                              fontSize: 9,
                            ),
                          ],
                          if (dateStr.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(dateStr,
                                style: AppTextStyles.caption.copyWith(fontSize: 10)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────
// 情報チップ（資格数・完了数表示用）
// ────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
