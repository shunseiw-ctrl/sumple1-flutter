import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/pages/admin/admin_job_management_tab.dart';
import 'package:sumple1/pages/admin/admin_applicants_tab.dart';

/// 案件管理 + 応募者管理 統合タブ
class AdminJobsAndApplicantsTab extends StatefulWidget {
  const AdminJobsAndApplicantsTab({super.key});

  @override
  State<AdminJobsAndApplicantsTab> createState() =>
      _AdminJobsAndApplicantsTabState();
}

class _AdminJobsAndApplicantsTabState
    extends State<AdminJobsAndApplicantsTab> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('admin_jobs_and_applicants');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text(context.l10n.adminNav_jobManagement,
                    style: const TextStyle(fontSize: 13)),
                icon: const Icon(Icons.work, size: 16),
              ),
              ButtonSegment(
                value: 1,
                label: Text(context.l10n.adminNav_applicants,
                    style: const TextStyle(fontSize: 13)),
                icon: const Icon(Icons.people, size: 16),
              ),
            ],
            selected: {_selectedIndex},
            onSelectionChanged: (selected) {
              setState(() => _selectedIndex = selected.first);
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: const [
              AdminJobManagementTab(),
              AdminApplicantsTab(),
            ],
          ),
        ),
      ],
    );
  }
}
