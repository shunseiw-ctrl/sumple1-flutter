import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/presentation/widgets/job_card.dart';

/// Compact square card for grid display (2x2 layout like Timmy).
class JobCardGrid extends StatelessWidget {
  final String title;
  final String location;
  final String dateText;
  final String priceText;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? category;
  final Map<String, dynamic> data;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final String? distanceLabel;

  const JobCardGrid({
    super.key,
    required this.title,
    required this.location,
    required this.dateText,
    required this.priceText,
    this.imageUrl,
    this.imageUrls = const [],
    this.category,
    required this.data,
    this.isFavorite = false,
    required this.onTap,
    this.onToggleFavorite,
    this.distanceLabel,
  });

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

  /// imageUrlsから先頭画像を取得
  String? get _effectiveImageUrl {
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _effectiveImageUrl;
    final hasImage = effectiveUrl != null && effectiveUrl.isNotEmpty;
    final colors = context.appColors;

    return Semantics(
      label: context.l10n.jobCard_semanticsLabel(title, location, dateText, priceText),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: colors.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      AppCachedImage(
                        imageUrl: effectiveUrl,
                        fit: BoxFit.cover,
                        errorWidget: _placeholderImage(context),
                      )
                    else
                      _placeholderImage(context),

                    // Gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Category badge
                    if (category != null && category!.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(JobCard.categoryIcon(category), size: 10, color: colors.primary),
                              const SizedBox(width: 2),
                              Text(
                                category!,
                                style: AppTextStyles.overline.copyWith(
                                  color: colors.primary,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // NEW badge
                    if (_isNewJob())
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.error,
                            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          ),
                          child: Text(
                            'NEW',
                            style: AppTextStyles.overline.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                    // Favorite button
                    if (onToggleFavorite != null)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onToggleFavorite,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavorite ? colors.error : colors.textHint,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Info section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F0),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFFE0B2), width: 0.5),
                        ),
                        child: Text(
                          '$priceText${context.l10n.jobCard_perDay}',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Title
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),

                      // Location + date row
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 10, color: colors.textHint),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              style: AppTextStyles.caption.copyWith(
                                color: colors.textSecondary,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryPale, const Color(0xFFE0E7F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          JobCard.categoryIcon(category),
          size: 32,
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
