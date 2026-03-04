import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/providers/admin_work_reports_provider.dart';
import 'package:sumple1/core/services/worker_name_resolver.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/load_more_button.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';

/// 日報管理タブ
class AdminWorkReportsTab extends ConsumerStatefulWidget {
  const AdminWorkReportsTab({super.key});

  @override
  ConsumerState<AdminWorkReportsTab> createState() => _AdminWorkReportsTabState();
}

class _AdminWorkReportsTabState extends ConsumerState<AdminWorkReportsTab> {
  final WorkerNameResolver _nameResolver = WorkerNameResolver();
  final Map<String, String> _resolvedNames = {};

  Future<void> _resolveNames(List<WorkReportItem> items) async {
    final uids = items
        .map((i) => i.workerUid)
        .where((uid) => uid.isNotEmpty && !_resolvedNames.containsKey(uid))
        .toSet()
        .toList();

    if (uids.isEmpty) return;

    final names = await _nameResolver.resolveNames(uids);
    if (mounted) {
      setState(() => _resolvedNames.addAll(names));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminWorkReportsProvider);

    return asyncState.when(
      loading: () => SkeletonList(itemBuilder: (_) => const SkeletonWorkCard()),
      error: (error, _) => Center(child: Text(context.l10n.common_loadError('$error'))),
      data: (state) {
        // ワーカー名の解決（build外で非同期実行）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _resolveNames(state.items);
        });

        if (state.items.isEmpty) {
          return EmptyState(
            icon: Icons.description_outlined,
            title: context.l10n.adminWorkReports_emptyTitle,
            description: context.l10n.adminWorkReports_emptyDescription,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(adminWorkReportsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: AppSpacing.listInsets,
            itemCount: state.items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == state.items.length) {
                return LoadMoreButton(
                  hasMore: state.hasMore,
                  isLoading: state.isLoadingMore,
                  onPressed: () => ref.read(adminWorkReportsProvider.notifier).loadMore(),
                );
              }

              final item = state.items[index];
              final workerName = _resolvedNames[item.workerUid] ?? '';

              return StaggeredFadeSlide(
                index: index,
                child: _WorkReportCard(item: item, workerName: workerName),
              );
            },
          ),
        );
      },
    );
  }
}

class _WorkReportCard extends StatelessWidget {
  final WorkReportItem item;
  final String workerName;

  const _WorkReportCard({required this.item, required this.workerName});

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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付 + ワーカー名
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: context.appColors.textHint),
              const SizedBox(width: 4),
              Text(
                item.reportDate,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(Icons.person, size: 14, color: context.appColors.textHint),
              const SizedBox(width: 4),
              Text(
                workerName.isNotEmpty ? workerName : 'UID: ${item.workerUid.length > 8 ? item.workerUid.substring(0, 8) : item.workerUid}...',
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // 作業時間
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: context.appColors.textHint),
              const SizedBox(width: 4),
              Text(
                context.l10n.adminWorkReports_hours(item.hoursWorked.toString()),
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // 作業内容
          Text(
            item.workContent,
            style: TextStyle(
              fontSize: 13,
              color: context.appColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // 写真サムネイル
          if (item.photoUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AppCachedImage(
                      imageUrl: item.photoUrls[i],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
