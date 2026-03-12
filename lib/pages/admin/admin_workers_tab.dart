import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/providers/admin_active_workers_provider.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/pages/admin/admin_work_reports_tab.dart';
import 'package:sumple1/pages/admin/admin_inspections_tab.dart';
import 'package:sumple1/presentation/widgets/admin_search_bar.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';

/// ワーカータブ（稼働一覧 + 日報 + 検査）
class AdminWorkersTab extends ConsumerStatefulWidget {
  const AdminWorkersTab({super.key});

  @override
  ConsumerState<AdminWorkersTab> createState() => _AdminWorkersTabState();
}

class _AdminWorkersTabState extends ConsumerState<AdminWorkersTab> {
  int _subTabIndex = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('admin_workers');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // サブナビ
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text(context.l10n.adminWorkers_activeList, style: const TextStyle(fontSize: 13)),
                icon: const Icon(Icons.people, size: 16),
              ),
              ButtonSegment(
                value: 1,
                label: Text(context.l10n.adminWorkers_reports, style: const TextStyle(fontSize: 13)),
                icon: const Icon(Icons.description, size: 16),
              ),
              ButtonSegment(
                value: 2,
                label: Text(context.l10n.adminWorkers_inspections, style: const TextStyle(fontSize: 13)),
                icon: const Icon(Icons.checklist, size: 16),
              ),
            ],
            selected: {_subTabIndex},
            onSelectionChanged: (selected) {
              setState(() => _subTabIndex = selected.first);
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: IndexedStack(
            index: _subTabIndex,
            children: const [
              _ActiveWorkersList(),
              AdminWorkReportsTab(),
              AdminInspectionsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveWorkersList extends ConsumerWidget {
  const _ActiveWorkersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(adminActiveWorkersProvider);

    return asyncState.when(
      loading: () => SkeletonList(itemBuilder: (_) => const SkeletonWorkCard()),
      error: (error, _) => Center(child: Text(context.l10n.common_loadError('$error'))),
      data: (state) {
        final searchedItems = state.filteredItems((item, query) {
          return item.name.toLowerCase().contains(query.toLowerCase());
        });

        // サマリー
        final inProgressCount = state.items.where((i) => i.status == 'in_progress').length;
        final assignedCount = state.items.where((i) => i.status == 'assigned').length;

        return Column(
          children: [
            // サマリーチップ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              child: Row(
                children: [
                  _SummaryChip(
                    label: context.l10n.adminWorkers_inProgressCount(inProgressCount.toString()),
                    color: context.appColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _SummaryChip(
                    label: context.l10n.adminWorkers_assignedCount(assignedCount.toString()),
                    color: context.appColors.info,
                  ),
                ],
              ),
            ),
            // 検索バー
            AdminSearchBar(
              hintText: context.l10n.adminWorkers_searchHint,
              onChanged: (query) {
                ref.read(adminActiveWorkersProvider.notifier).setSearchQuery(query);
              },
            ),
            // リスト
            Expanded(
              child: searchedItems.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: context.l10n.adminWorkers_emptyTitle,
                      description: context.l10n.adminWorkers_emptyDescription,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(adminActiveWorkersProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: AppSpacing.listInsets,
                        itemCount: searchedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final worker = searchedItems[index];
                          return StaggeredFadeSlide(
                            index: index,
                            child: _WorkerCard(worker: worker),
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
}

class _WorkerCard extends StatelessWidget {
  final ActiveWorkerItem worker;
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final isActive = worker.status == 'in_progress';

    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: () => context.push(RoutePaths.adminWorkerDetailPath(worker.uid)),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: context.appColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isActive
                    ? context.appColors.primary.withValues(alpha: 0.1)
                    : context.appColors.chipUnselected,
                child: Icon(
                  Icons.person,
                  color: isActive ? context.appColors.primary : context.appColors.textHint,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name.isNotEmpty ? worker.name : 'UID: ${worker.uid.length > 8 ? worker.uid.substring(0, 8) : worker.uid}...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (worker.latestJobTitle.isNotEmpty)
                      Text(
                        worker.latestJobTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.appColors.primary.withValues(alpha: 0.1)
                          : context.appColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                    ),
                    child: Text(
                      '${worker.activeJobCount}${context.l10n.adminWorkers_jobUnit}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? context.appColors.primary : context.appColors.info,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: context.appColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

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
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
