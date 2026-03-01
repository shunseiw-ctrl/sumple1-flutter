import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RatingStarsDisplay extends StatelessWidget {
  final double average;
  final int count;
  final double starSize;
  final double fontSize;

  const RatingStarsDisplay({
    super.key,
    required this.average,
    required this.count,
    this.starSize = 18,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        '評価なし',
        style: TextStyle(
          fontSize: fontSize,
          color: AppColors.textHint,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final starNum = i + 1;
          if (average >= starNum) {
            return Icon(Icons.star_rounded, size: starSize, color: Colors.amber);
          } else if (average >= starNum - 0.5) {
            return Icon(Icons.star_half_rounded, size: starSize, color: Colors.amber);
          } else {
            return Icon(Icons.star_outline_rounded, size: starSize, color: AppColors.textHint);
          }
        }),
        const SizedBox(width: 6),
        Text(
          average.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count件)',
          style: TextStyle(
            fontSize: fontSize - 1,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
