import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/providers/admin_inspections_provider.dart';
import 'package:sumple1/presentation/widgets/admin_filter_chips.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/load_more_button.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';

/// 検査管理タブ
class AdminInspectionsTab extends ConsumerWidget {
  const AdminInspectionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(adminInspectionsProvider);

    return asyncState.when(
      loading: () => SkeletonList(itemBuilder: (_) => const SkeletonWorkCard()),
      error: (error, _) => Center(child: Text(context.l10n.common_loadError('$error'))),
      data: (state) {
        return Column(
          children: [
            // フィルタ
            AdminFilterChips(
              selectedKey: state.filterStatus,
              options: {
                'all': context.l10n.adminInspections_filterAll,
                'passed': context.l10n.adminInspections_filterPassed,
                'failed': context.l10n.adminInspections_filterFailed,
                'partial': context.l10n.adminInspections_filterPartial,
              },
              onSelected: (key) {
                ref.read(adminInspectionsProvider.notifier).setFilter(key);
              },
            ),
            Expanded(
              child: state.items.isEmpty
                  ? EmptyState(
                      icon: Icons.checklist,
                      title: context.l10n.adminInspections_emptyTitle,
                      description: context.l10n.adminInspections_emptyDescription,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(adminInspectionsProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: AppSpacing.listInsets,
                        itemCount: state.items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return LoadMoreButton(
                              hasMore: state.hasMore,
                              isLoading: state.isLoadingMore,
                              onPressed: () => ref.read(adminInspectionsProvider.notifier).loadMore(),
                            );
                          }
                          return StaggeredFadeSlide(
                            index: index,
                            child: _InspectionCard(item: state.items[index]),
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

class _InspectionCard extends StatelessWidget {
  final InspectionItem item;
  const _InspectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    if (item.createdAt != null) {
      final d = item.createdAt!;
      dateStr = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    }

    IconData resultIcon;
    Color resultColor;
    String resultLabel;
    switch (item.result) {
      case 'passed':
        resultIcon = Icons.check_circle;
        resultColor = context.appColors.success;
        resultLabel = context.l10n.adminInspections_passed;
        break;
      case 'failed':
        resultIcon = Icons.cancel;
        resultColor = context.appColors.error;
        resultLabel = context.l10n.adminInspections_failed;
        break;
      default:
        resultIcon = Icons.warning;
        resultColor = context.appColors.warning;
        resultLabel = context.l10n.adminInspections_partial;
    }

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
          Row(
            children: [
              Icon(resultIcon, size: 20, color: resultColor),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Text(
                  resultLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: resultColor,
                  ),
                ),
              ),
              const Spacer(),
              if (dateStr.isNotEmpty)
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textHint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // チェック項目サマリー
          Text(
            context.l10n.adminInspections_checkSummary(
              item.totalItems.toString(),
              item.passedItems.toString(),
            ),
            style: TextStyle(
              fontSize: 13,
              color: context.appColors.textPrimary,
            ),
          ),
          if (item.overallComment != null && item.overallComment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.overallComment!,
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
