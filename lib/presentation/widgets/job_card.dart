import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/presentation/widgets/job_image_slider.dart';
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
  final List<String> imageUrls;
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
  final String? distanceLabel;

  const JobCard({
    super.key,
    required this.title,
    required this.location,
    required this.dateText,
    required this.priceText,
    this.imageUrl,
    this.imageUrls = const [],
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
    this.distanceLabel,
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

  /// imageUrls用のヘルパー: imageUrlsが空ならimageUrlをフォールバック
  List<String> get _effectiveImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.jobCard_semanticsLabel(title, location, dateText, priceText),
      child: ScaleTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像スライダー + オーバーレイUI
            Stack(
              children: [
                JobImageSlider(
                  imageUrls: _effectiveImageUrls,
                  category: category,
                  heroTag: heroTag,
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
                          Icon(categoryIcon(category), size: 14, color: context.appColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            category!,
                            style: AppTextStyles.badgeText.copyWith(color: context.appColors.primary),
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
                    label: isFavorite ? context.l10n.jobCard_removeFavorite : context.l10n.jobCard_addFavorite,
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
                          color: isFavorite ? context.appColors.error : context.appColors.textHint,
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
                        tooltip: context.l10n.jobCard_actions,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                        iconSize: 20,
                        icon: Icon(Icons.more_horiz_rounded, color: context.appColors.textSecondary, size: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
                        onSelected: (v) {
                          if (v == 'edit') onEdit?.call();
                          if (v == 'delete') onDelete?.call();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(context.l10n.jobCard_edit, style: AppTextStyles.bodyMedium)),
                          PopupMenuItem(value: 'delete', child: Text(context.l10n.jobCard_delete, style: AppTextStyles.bodyMedium.copyWith(color: context.appColors.error))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 価格を画像直下に配置（大きく表示）
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE0B2), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          priceText,
                          style: AppTextStyles.salary,
                        ),
                        Text(context.l10n.jobCard_perDay, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: context.appColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distanceLabel != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.appColors.primaryPale,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            distanceLabel!,
                            style: AppTextStyles.badgeText.copyWith(
                              color: context.appColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.md),
                      Icon(Icons.calendar_today_outlined, size: 14, color: context.appColors.textHint),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        dateText,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // メトリクス + バッジ
                  Row(
                    children: [
                      Expanded(child: _buildMetricsRow(context, JobCardMetrics.fromData(data))),
                      if (badges.isNotEmpty || showLegacyWarning || _isNewJob())
                        Wrap(
                          spacing: 4,
                          children: [
                            if (_isNewJob())
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: context.appColors.error,
                                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                                ),
                                child: Text(
                                  'NEW',
                                  style: AppTextStyles.badgeText.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ),
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
                                  color: context.appColors.warningLight,
                                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                                ),
                                child: Text(
                                  context.l10n.jobCard_noOwnerId,
                                  style: AppTextStyles.badgeText.copyWith(color: const Color(0xFFE65100)),
                                ),
                              ),
                          ],
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

  bool _isNewJob() {
    final createdAt = data['createdAt'];
    if (createdAt == null) return false;
    DateTime? created;
    if (createdAt is Timestamp) {
      created = createdAt.toDate();
    } else if (createdAt is DateTime) {
      created = createdAt;
    }
    if (created == null) return false;
    return DateTime.now().difference(created).inHours < 24;
  }

  Widget _buildMetricsRow(BuildContext context, JobCardMetrics metrics) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: metrics.isUrgent ? colors.errorLight : colors.warningLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metrics.isUrgent ? Icons.local_fire_department : Icons.people_outline,
                size: 12,
                color: metrics.isUrgent ? colors.error : colors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.jobCard_remainingSlots(metrics.remainingSlots.toString()),
                style: AppTextStyles.badgeText.copyWith(
                  color: metrics.isUrgent ? colors.error : colors.warning,
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
              color: colors.successLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              context.l10n.jobCard_quickStart,
              style: AppTextStyles.badgeText.copyWith(color: colors.success),
            ),
          ),
      ],
    );
  }

}
