import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/route_paths.dart';
import '../../core/services/work_report_service.dart';
import '../../data/models/work_report_model.dart';

/// 日報一覧タブ
class WorkReportsTab extends StatelessWidget {
  final String applicationId;
  final WorkReportService? reportService;

  const WorkReportsTab({
    super.key,
    required this.applicationId,
    this.reportService,
  });

  @override
  Widget build(BuildContext context) {
    final service = reportService ?? WorkReportService();

    return Scaffold(
      body: StreamBuilder<List<WorkReportModel>>(
        stream: service.watchReports(applicationId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('エラー: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snap.data!;
          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('日報はまだありません', style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('右下のボタンから作成できます', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.description, color: AppColors.ruri),
                  title: Text(
                    report.reportDate,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    report.workContent,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${report.hoursWorked}h',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ruri),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(RoutePaths.workReportCreatePath(applicationId));
        },
        backgroundColor: AppColors.ruri,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
