import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/activity_log_service.dart';
import '../../data/models/activity_log_model.dart';

/// 工程タイムラインタブ
class TimelineTab extends StatelessWidget {
  final String applicationId;
  final ActivityLogService? logService;

  const TimelineTab({
    super.key,
    required this.applicationId,
    this.logService,
  });

  IconData _iconForEvent(String eventType) {
    return switch (eventType) {
      'status_change' => Icons.swap_horiz,
      'checkin' => Icons.login,
      'checkout' => Icons.logout,
      'report_submitted' => Icons.description,
      'inspection_completed' => Icons.check_circle,
      'note_added' => Icons.note_add,
      _ => Icons.circle,
    };
  }

  Color _colorForEvent(String eventType) {
    return switch (eventType) {
      'status_change' => AppColors.ruri,
      'checkin' => Colors.green,
      'checkout' => Colors.orange,
      'report_submitted' => Colors.blue,
      'inspection_completed' => Colors.teal,
      'note_added' => AppColors.textSecondary,
      _ => AppColors.textHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    final service = logService ?? ActivityLogService();

    return StreamBuilder<List<ActivityLogModel>>(
      stream: service.watchTimeline(applicationId),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('エラー: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snap.data!;
        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timeline, size: 48, color: AppColors.textHint),
                SizedBox(height: 12),
                Text('タイムラインはまだありません', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final color = _colorForEvent(log.eventType);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_iconForEvent(log.eventType),
                            size: 16, color: color),
                      ),
                      if (index < logs.length - 1)
                        Container(
                          width: 2,
                          height: 32,
                          color: AppColors.divider,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (log.createdAt != null)
                          Text(
                            _formatDateTime(log.createdAt!),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textHint),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
