import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

/// KPI数値表示カード（前期比矢印付き）
class AdminKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? previousValue;
  final IconData icon;
  final Color iconColor;

  const AdminKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.previousValue,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // 前月比の計算
    Widget? trendWidget;
    if (previousValue != null) {
      final current = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final previous = double.tryParse(previousValue!.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

      if (previous > 0) {
        final change = ((current - previous) / previous * 100).round();
        final isUp = change > 0;
        final isDown = change < 0;

        trendWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUp ? Icons.trending_up : isDown ? Icons.trending_down : Icons.trending_flat,
              size: 14,
              color: isUp
                  ? context.appColors.success
                  : isDown
                      ? context.appColors.error
                      : context.appColors.textHint,
            ),
            const SizedBox(width: 2),
            Text(
              '${isUp ? '+' : ''}$change%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isUp
                    ? context.appColors.success
                    : isDown
                        ? context.appColors.error
                        : context.appColors.textHint,
              ),
            ),
          ],
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(14),
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
              if (trendWidget != null) trendWidget,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
