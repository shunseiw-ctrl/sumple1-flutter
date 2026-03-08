import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/presentation/widgets/job_card.dart';

/// 案件画像のプレースホルダー（共通ウィジェット）
/// job_card_grid, job_image_slider, job_detail_page で共用
class JobPlaceholderImage extends StatelessWidget {
  final String? category;
  final double iconSize;

  const JobPlaceholderImage({
    super.key,
    this.category,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryPale, colors.placeholderGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          JobCard.categoryIcon(category),
          size: iconSize,
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
