import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';

class WorkPage extends StatefulWidget {
  const WorkPage({super.key});

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage>
    with SingleTickerProviderStateMixin {
  bool _notAnonymous(User? u) => u != null && !u.isAnonymous;

  Key _refreshKey = UniqueKey();

  late final TabController _statusTabController;

  List<_StatusTab> _buildStatusTabs(BuildContext context) => <_StatusTab>[
    _StatusTab(key: 'my_applications', label: context.l10n.work_tabApplications),
    _StatusTab(key: 'assigned', label: context.l10n.work_tabAssigned),
    _StatusTab(key: 'in_progress', label: context.l10n.work_tabInProgress),
    _StatusTab(key: 'completed', label: context.l10n.work_tabCompleted),
    _StatusTab(key: 'inspection', label: context.l10n.work_tabInspection),
    _StatusTab(key: 'fixing', label: context.l10n.work_tabFixing),
    _StatusTab(key: 'done', label: context.l10n.work_tabDone),
  ];

  static const _tabCount = 7;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('work');
    _statusTabController = TabController(length: _tabCount, vsync: this);
    _statusTabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    super.dispose();
  }

  static const _statusKeys = [
    'my_applications',
    'assigned',
    'in_progress',
    'completed',
    'inspection',
    'fixing',
    'done',
  ];

  String _emptyMessageFor(BuildContext context, String statusKey) {
    switch (statusKey) {
      case 'my_applications':
        return context.l10n.work_emptyApplications;
      case 'assigned':
        return context.l10n.work_emptyAssigned;
      case 'in_progress':
        return context.l10n.work_emptyInProgress;
      case 'completed':
        return context.l10n.work_emptyCompleted;
      case 'inspection':
        return context.l10n.work_emptyInspection;
      case 'fixing':
        return context.l10n.work_emptyFixing;
      case 'done':
        return context.l10n.work_emptyDone;
      default:
        return context.l10n.work_emptyDefault;
    }
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  void _sortByCreatedAtDesc(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    docs.sort((a, b) {
      final ad = _toDate(a.data()['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _toDate(b.data()['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
  }

  void _navigateToDetail(BuildContext context, String applicationId) {
    context.push(RoutePaths.workDetailPath(applicationId));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final statusTabs = _buildStatusTabs(context);

    if (!_notAnonymous(user)) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        body: SafeArea(
          child: EmptyState(
            icon: Icons.work_outline,
            title: context.l10n.work_registrationRequiredTitle,
            description: context.l10n.work_registrationRequiredDescription,
            actionText: context.l10n.common_registerToStart,
            onAction: () => RegistrationPromptModal.show(context, featureName: context.l10n.work_featureName),
          ),
        ),
      );
    }

    final uid = user!.uid;

    final tabIndex = _statusTabController.index.clamp(0, statusTabs.length - 1);
    final selectedStatusKey = _statusKeys[tabIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: context.appColors.surface,
              elevation: 0,
              child: TabBar(
                controller: _statusTabController,
                isScrollable: true,
                labelColor: context.appColors.primary,
                unselectedLabelColor: context.appColors.textSecondary,
                indicatorColor: context.appColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.appColors.primary),
                unselectedLabelStyle: AppTextStyles.labelMedium,
                tabs: statusTabs.map((t) => Tab(text: t.label)).toList(),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                key: _refreshKey,
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('applicantUid', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text(context.l10n.common_loadError('${snap.error}')));
                  }
                  if (!snap.hasData) {
                    return SkeletonList(itemBuilder: (_) => const SkeletonWorkCard());
                  }

                  final allDocs = snap.data!.docs.toList();
                  _sortByCreatedAtDesc(allDocs);

                  List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered;
                  if (selectedStatusKey == 'my_applications') {
                    filtered = allDocs;
                  } else if (selectedStatusKey == 'assigned') {
                    filtered = allDocs.where((d) {
                      final status = (d.data()['status'] ?? 'applied').toString();
                      return status == 'assigned' || status == 'applied';
                    }).toList();
                  } else {
                    filtered = allDocs.where((d) {
                      final status = (d.data()['status'] ?? 'applied').toString();
                      return status == selectedStatusKey;
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.inbox_outlined,
                      title: _emptyMessageFor(context, selectedStatusKey),
                      description: '',
                    );
                  }

                  if (selectedStatusKey == 'my_applications') {
                    final pending = filtered.where((d) {
                      final s = (d.data()['status'] ?? 'applied').toString();
                      return s == 'applied';
                    }).toList();

                    final approved = filtered.where((d) {
                      final s = (d.data()['status'] ?? '').toString();
                      return s == 'assigned' || s == 'in_progress';
                    }).toList();

                    final completed = filtered.where((d) {
                      final s = (d.data()['status'] ?? '').toString();
                      return s == 'completed' || s == 'inspection' || s == 'fixing' || s == 'done';
                    }).toList();

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _refreshKey = UniqueKey());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: context.appColors.primary,
                      child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, AppSpacing.xl),
                      children: [
                        _StatusGroup(
                          title: context.l10n.work_groupApplied,
                          icon: Icons.hourglass_empty,
                          color: context.appColors.warning,
                          count: pending.length,
                          docs: pending,
                          onTapItem: (appId) => _navigateToDetail(context, appId),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _StatusGroup(
                          title: context.l10n.work_groupApproved,
                          icon: Icons.check_circle_outline,
                          color: context.appColors.primary,
                          count: approved.length,
                          docs: approved,
                          onTapItem: (appId) => _navigateToDetail(context, appId),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _StatusGroup(
                          title: context.l10n.work_groupCompleted,
                          icon: Icons.done_all,
                          color: context.appColors.success,
                          count: completed.length,
                          docs: completed,
                          onTapItem: (appId) => _navigateToDetail(context, appId),
                        ),
                      ],
                    ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() => _refreshKey = UniqueKey());
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: context.appColors.primary,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      cacheExtent: AppConstants.listCacheExtent,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, AppSpacing.xl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final appDoc = filtered[i];
                      final applicationId = appDoc.id;
                      final app = appDoc.data();

                      final titleSnap = (app['jobTitleSnapshot'] ??
                          app['projectNameSnapshot'] ??
                          '')
                          .toString();

                      final statusKey = (app['status'] ?? 'applied').toString();

                      return _WhiteCard(
                        child: ListTile(
                          title: Text(
                            titleSnap.isNotEmpty ? titleSnap : context.l10n.common_job,
                            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: StatusBadge.fromStatus(context, statusKey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: context.l10n.work_chatTooltip,
                                icon: const Icon(Icons.chat_bubble_outline),
                                onPressed: () {
                                  context.push(RoutePaths.chatRoomPath(applicationId));
                                },
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            context.push(RoutePaths.workDetailPath(applicationId));
                          },
                        ),
                      );
                    },
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTab {
  final String key;
  final String label;
  const _StatusTab({required this.key, required this.label});
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final void Function(String applicationId) onTapItem;

  const _StatusGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.docs,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Text('$count', style: AppTextStyles.badgeText.copyWith(color: color)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
            child: Text(context.l10n.work_noJobs, style: AppTextStyles.bodySmall),
          )
        else
          ...docs.map((appDoc) {
            final app = appDoc.data();
            final titleSnap = (app['jobTitleSnapshot'] ?? app['projectNameSnapshot'] ?? '').toString();
            final statusKey = (app['status'] ?? 'applied').toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _WhiteCard(
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    titleSnap.isNotEmpty ? titleSnap : context.l10n.common_job,
                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: StatusBadge.fromStatus(context, statusKey),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => onTapItem(appDoc.id),
                ),
              ),
            );
          }),
      ],
    );
  }
}
