import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

/// KPIミニバーチャート（直近7日間のデータ表示）
class AdminMiniBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final Color? barColor;

  const AdminMiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 100,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            context.l10n.adminKpi_noData,
            style: TextStyle(
              fontSize: 12,
              color: context.appColors.textHint,
            ),
          ),
        ),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue > 0 ? maxValue : 1.0;
    final color = barColor ?? context.appColors.primary;

    return SizedBox(
      height: height + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final ratio = values[index] / effectiveMax;
          final barHeight = ratio * height;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 数値ラベル
                  Text(
                    values[index].toInt().toString(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // バー
                  Container(
                    height: barHeight.clamp(2.0, height),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2 + 0.6 * ratio),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 日付ラベル
                  Text(
                    index < labels.length ? labels[index] : '',
                    style: TextStyle(
                      fontSize: 9,
                      color: context.appColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
