import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

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

  /// ステータスキーからラベルを取得（i18n対応）
  static String labelFor(String statusKey, [BuildContext? context]) {
    if (context != null) {
      switch (statusKey) {
        case 'applied': return context.l10n.statusBadge_applied;
        case 'assigned': return context.l10n.statusBadge_assigned;
        case 'in_progress': return context.l10n.statusBadge_inProgress;
        case 'completed': return context.l10n.statusBadge_completed;
        case 'inspection': return context.l10n.statusBadge_inspection;
        case 'fixing': return context.l10n.statusBadge_fixing;
        case 'done': return context.l10n.statusBadge_done;
        default: return statusKey;
      }
    }
    // Fallback for cases without context (English)
    switch (statusKey) {
      case 'applied': return 'Applied';
      case 'assigned': return 'Assigned';
      case 'in_progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'inspection': return 'Inspection';
      case 'fixing': return 'Fixing';
      case 'done': return 'Done';
      default: return statusKey;
    }
  }

  /// ステータスキーからカラーを取得
  static Color colorFor(BuildContext context, String statusKey) {
    final colors = context.appColors;
    switch (statusKey) {
      case 'applied': return colors.warning;
      case 'assigned': return colors.info;
      case 'in_progress': return colors.primary;
      case 'completed': return colors.success;
      case 'inspection': return colors.inspection;
      case 'fixing': return colors.error;
      case 'done': return colors.success;
      default: return colors.textSecondary;
    }
  }

  factory StatusBadge.fromStatus(BuildContext context, String statusKey) {
    final colors = context.appColors;
    final label = labelFor(statusKey, context);
    switch (statusKey) {
      case 'applied':
        return StatusBadge(label: label, color: colors.warning, icon: Icons.schedule);
      case 'assigned':
        return StatusBadge(label: label, color: colors.info, icon: Icons.assignment_turned_in);
      case 'in_progress':
        return StatusBadge(label: label, color: colors.primary, icon: Icons.engineering, filled: true);
      case 'completed':
        return StatusBadge(label: label, color: colors.success, icon: Icons.check_circle_outline);
      case 'inspection':
        return StatusBadge(label: label, color: colors.inspection, icon: Icons.visibility);
      case 'fixing':
        return StatusBadge(label: label, color: colors.error, icon: Icons.build);
      case 'done':
        return StatusBadge(label: label, color: colors.success, icon: Icons.done_all, filled: true);
      default:
        return StatusBadge(label: label, color: colors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.3), width: 1),
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
