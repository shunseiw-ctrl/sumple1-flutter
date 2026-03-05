import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/providers/admin_work_reports_provider.dart';
import 'package:sumple1/core/services/work_report_service.dart';
import 'package:sumple1/core/services/worker_name_resolver.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/pages/admin/work_report_feedback_dialog.dart';
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
  String _filter = 'all'; // 'all' | 'pending' | 'reviewed'

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

  List<WorkReportItem> _applyFilter(List<WorkReportItem> items) {
    if (_filter == 'pending') return items.where((i) => i.isPending).toList();
    if (_filter == 'reviewed') return items.where((i) => i.isReviewed).toList();
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminWorkReportsProvider);

    return asyncState.when(
      loading: () => SkeletonList(itemBuilder: (_) => const SkeletonWorkCard()),
      error: (error, _) => Center(child: Text(context.l10n.common_loadError('$error'))),
      data: (state) {
        // ワーカー名の解決
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _resolveNames(state.items);
        });

        final filtered = _applyFilter(state.items);

        return Column(
          children: [
            // フィルタチップ
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  _FilterChip(
                    label: context.l10n.adminWorkReports_filterAll,
                    selected: _filter == 'all',
                    onSelected: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: context.l10n.adminWorkReports_filterPending,
                    selected: _filter == 'pending',
                    onSelected: () => setState(() => _filter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: context.l10n.adminWorkReports_filterReviewed,
                    selected: _filter == 'reviewed',
                    onSelected: () => setState(() => _filter = 'reviewed'),
                  ),
                ],
              ),
            ),
            // リスト
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.description_outlined,
                      title: context.l10n.adminWorkReports_emptyTitle,
                      description: context.l10n.adminWorkReports_emptyDescription,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(adminWorkReportsProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: AppSpacing.listInsets,
                        itemCount: filtered.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            return LoadMoreButton(
                              hasMore: state.hasMore,
                              isLoading: state.isLoadingMore,
                              onPressed: () => ref.read(adminWorkReportsProvider.notifier).loadMore(),
                            );
                          }

                          final item = filtered[index];
                          final workerName = _resolvedNames[item.workerUid] ?? '';

                          return StaggeredFadeSlide(
                            index: index,
                            child: _WorkReportCard(
                              item: item,
                              workerName: workerName,
                              onFeedback: () => _showFeedbackDialog(item),
                              onMarkReviewed: () => _markReviewed(item),
                            ),
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

  Future<void> _showFeedbackDialog(WorkReportItem item) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (_) => WorkReportFeedbackDialog(reportDate: item.reportDate),
    );
    if (comment == null || !mounted) return;

    try {
      final service = WorkReportService();
      await service.addFeedback(
        applicationId: item.applicationId,
        reportId: item.id,
        comment: comment,
      );
      AppHaptics.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminWorkReports_feedbackSent)),
        );
        ref.read(adminWorkReportsProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminWorkReports_feedbackFailed)),
        );
      }
    }
  }

  Future<void> _markReviewed(WorkReportItem item) async {
    try {
      final service = WorkReportService();
      await service.markAsReviewed(
        applicationId: item.applicationId,
        reportId: item.id,
      );
      AppHaptics.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminWorkReports_markedReviewed)),
        );
        ref.read(adminWorkReportsProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminWorkReports_markFailed)),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : context.appColors.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: context.appColors.primary,
      backgroundColor: context.appColors.surface,
      side: BorderSide(color: context.appColors.divider),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _WorkReportCard extends StatelessWidget {
  final WorkReportItem item;
  final String workerName;
  final VoidCallback onFeedback;
  final VoidCallback onMarkReviewed;

  const _WorkReportCard({
    required this.item,
    required this.workerName,
    required this.onFeedback,
    required this.onMarkReviewed,
  });

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
          // 日付 + ワーカー名 + レビューバッジ
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
              // レビューステータスバッジ
              _ReviewBadge(isReviewed: item.isReviewed),
            ],
          ),
          const SizedBox(height: 6),
          // ワーカー名
          Row(
            children: [
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
          // 管理者コメント（あれば表示）
          if (item.adminComment != null && item.adminComment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.appColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment, size: 14, color: context.appColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.adminComment!,
                      style: TextStyle(fontSize: 12, color: context.appColors.textPrimary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          // アクションボタン
          if (item.isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onFeedback,
                  icon: const Icon(Icons.comment_outlined, size: 16),
                  label: Text(context.l10n.adminWorkReports_addFeedback, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onMarkReviewed,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(context.l10n.adminWorkReports_markReviewed, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  final bool isReviewed;

  const _ReviewBadge({required this.isReviewed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isReviewed
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isReviewed
            ? context.l10n.adminWorkReports_reviewed
            : context.l10n.adminWorkReports_reviewPending,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isReviewed ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
