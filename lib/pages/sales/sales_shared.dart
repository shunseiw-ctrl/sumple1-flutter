import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

/// 影付きカード（SalesPage共通）
class SalesShadowCard extends StatelessWidget {
  final Widget child;
  const SalesShadowCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// ミニ統計表示
class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MiniStat({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
