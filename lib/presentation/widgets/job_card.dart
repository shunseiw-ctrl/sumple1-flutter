import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/presentation/widgets/scale_tap.dart';

/// Badge display specification for JobCard.
class BadgeSpec {
  final String label;
  final Color bg;
  final Color fg;
  const BadgeSpec({required this.label, required this.bg, required this.fg});
}

/// JobCard内のメトリクス計算を集約するデータクラス
class JobCardMetrics {
  final int remainingSlots;
  final bool isUrgent;
  final bool showQuickStart;

  const JobCardMetrics({
    required this.remainingSlots,
    required this.isUrgent,
    required this.showQuickStart,
  });

  factory JobCardMetrics.fromData(Map<String, dynamic> data) {
    final totalSlots = int.tryParse((data['slots'] ?? '5').toString()) ?? 5;
    final applicantCount = int.tryParse((data['applicantCount'] ?? '0').toString()) ?? 0;
    final remaining = (totalSlots - applicantCount).clamp(1, totalSlots);
    final isUrgent = remaining <= 2;
    final dateDiff = DateTime.tryParse(data['date'] ?? '')
        ?.difference(DateTime.now()).inDays ?? 999;
    final showQuickStart =
        (data['quickStart'] ?? false) == true || dateDiff.abs() <= 3;
    return JobCardMetrics(
      remainingSlots: remaining,
      isUrgent: isUrgent,
      showQuickStart: showQuickStart,
    );
  }
}

/// A card widget that displays a job listing with image, badges,
/// favorite button, popup menu, price, location, and date.
class JobCard extends StatelessWidget {
  final String title;
  final String location;
  final String dateText;
  final String priceText;
  final String? imageUrl;
  final String? category;
  final List<BadgeSpec> badges;
  final bool showLegacyWarning;
  final Map<String, dynamic> data;

  final bool isOwner;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final String? heroTag;

  const JobCard({
    super.key,
    required this.title,
    required this.location,
    required this.dateText,
    required this.priceText,
    this.imageUrl,
    this.category,
    required this.badges,
    required this.showLegacyWarning,
    required this.data,
    required this.isOwner,
    this.isFavorite = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onToggleFavorite,
    this.heroTag,
  });

  /// Returns the icon for a given construction category.
  static IconData categoryIcon(String? cat) {
    switch (cat) {
      case '解体':
        return Icons.handyman;
      case '内装':
        return Icons.format_paint;
      case '外壁':
        return Icons.home_work;
      case '電気':
        return Icons.electrical_services;
      case '配管':
        return Icons.plumbing;
      case '土木':
        return Icons.landscape;
      case '塗装':
        return Icons.brush;
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Semantics(
      label: '$title、場所: $location、日程: $dateText、報酬: $priceText',
      child: ScaleTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    heroTag != null
                        ? Hero(
                            tag: heroTag!,
                            child: AppCachedImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: _placeholderImage(),
                            ),
                          )
                        : AppCachedImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: _placeholderImage(),
                          )
                  else
                    _placeholderImage(),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (category != null && category!.isNotEmpty)
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon(category), size: 14, color: AppColors.ruri),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              category!,
                              style: AppTextStyles.badgeText.copyWith(color: AppColors.ruri),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Semantics(
                      button: true,
                      label: isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
                      child: GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.subtle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? AppColors.error : AppColors.textHint,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (isOwner)
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md + 44,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.subtle,
                        ),
                        child: PopupMenuButton<String>(
                          tooltip: '操作',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                          iconSize: 20,
                          icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary, size: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
                          onSelected: (v) {
                            if (v == 'edit') onEdit?.call();
                            if (v == 'delete') onDelete?.call();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'edit', child: Text('編集', style: AppTextStyles.bodyMedium)),
                            PopupMenuItem(value: 'delete', child: Text('削除', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badges.isNotEmpty || showLegacyWarning) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final b in badges)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: b.bg,
                              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                            ),
                            child: Text(
                              b.label,
                              style: AppTextStyles.badgeText.copyWith(color: b.fg),
                            ),
                          ),
                        if (showLegacyWarning)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                            ),
                            child: Text(
                              'ownerIdなし',
                              style: AppTextStyles.badgeText.copyWith(color: const Color(0xFFE65100)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _buildMetricsRow(JobCardMetrics.fromData(data)),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        priceText,
                        style: AppTextStyles.salary,
                      ),
                      Text(' /日', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.ruri),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textHint),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        dateText,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMetricsRow(JobCardMetrics metrics) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: metrics.isUrgent ? AppColors.errorLight : AppColors.warningLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metrics.isUrgent ? Icons.local_fire_department : Icons.people_outline,
                size: 12,
                color: metrics.isUrgent ? AppColors.error : AppColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                '残り${metrics.remainingSlots}枠',
                style: AppTextStyles.badgeText.copyWith(
                  color: metrics.isUrgent ? AppColors.error : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (metrics.showQuickStart)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '即日勤務OK',
              style: AppTextStyles.badgeText.copyWith(color: AppColors.success),
            ),
          ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Semantics(
      excludeSemantics: true,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.ruriPale, Color(0xFFE0E7F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            categoryIcon(category),
            size: 48,
            color: AppColors.ruri.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
