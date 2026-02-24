import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  factory StatusBadge.fromStatus(String statusKey) {
    switch (statusKey) {
      case 'applied':
        return const StatusBadge(label: '応募中', color: AppColors.warning, icon: Icons.schedule);
      case 'assigned':
        return const StatusBadge(label: '着工前', color: AppColors.info, icon: Icons.assignment_turned_in);
      case 'in_progress':
        return StatusBadge(label: '着工中', color: AppColors.ruri, icon: Icons.engineering, filled: true);
      case 'completed':
        return const StatusBadge(label: '施工完了', color: AppColors.success, icon: Icons.check_circle_outline);
      case 'inspection':
        return const StatusBadge(label: '検収中', color: Color(0xFF8B5CF6), icon: Icons.visibility);
      case 'fixing':
        return const StatusBadge(label: '是正中', color: AppColors.error, icon: Icons.build);
      case 'done':
        return StatusBadge(label: '完了', color: AppColors.success, icon: Icons.done_all, filled: true);
      default:
        return StatusBadge(label: statusKey, color: AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.badgeText.copyWith(
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}
