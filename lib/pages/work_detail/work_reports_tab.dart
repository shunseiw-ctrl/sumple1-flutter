import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/build_context_extensions.dart';
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
            return Center(child: Text(context.l10n.workReports_error(snap.error.toString())));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snap.data!;
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 48, color: context.appColors.textHint),
                  const SizedBox(height: 12),
                  Text(context.l10n.workReports_empty, style: TextStyle(color: context.appColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(context.l10n.workReports_addHint, style: TextStyle(color: context.appColors.textHint, fontSize: 12)),
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
                  leading: Icon(Icons.description, color: context.appColors.primary),
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
                    style: TextStyle(fontWeight: FontWeight.w700, color: context.appColors.primary),
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
        backgroundColor: context.appColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
