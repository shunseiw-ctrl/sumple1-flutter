import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'work_detail_page.dart';
import 'chat_room_page.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class WorkPage extends StatefulWidget {
  const WorkPage({super.key});

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage>
    with SingleTickerProviderStateMixin {
  bool _notAnonymous(User? u) => u != null && !u.isAnonymous;

  late final TabController _statusTabController;

  static const _statusTabs = <_StatusTab>[
    _StatusTab(key: 'my_applications', label: '応募状況'),
    _StatusTab(key: 'assigned', label: '着工前'),
    _StatusTab(key: 'in_progress', label: '着工中'),
    _StatusTab(key: 'completed', label: '施工完了'),
    _StatusTab(key: 'inspection', label: '検収中'),
    _StatusTab(key: 'fixing', label: '是正中'),
    _StatusTab(key: 'done', label: '完了'),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('work');
    _statusTabController = TabController(length: _statusTabs.length, vsync: this);
    _statusTabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    super.dispose();
  }

  String _emptyMessageFor(String statusKey) {
    switch (statusKey) {
      case 'my_applications':
        return '応募した案件はまだありません';
      case 'assigned':
        return '着工前の案件はまだありません';
      case 'in_progress':
        return '着工中の案件はまだありません';
      case 'completed':
        return '施工完了の案件はまだありません';
      case 'inspection':
        return '検収中の案件はまだありません（管理側の更新待ちです）';
      case 'fixing':
        return '是正中の案件はまだありません（管理側の更新待ちです）';
      case 'done':
        return '完了した案件はまだありません';
      default:
        return '案件はまだありません';
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkDetailPage(applicationId: applicationId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (!_notAnonymous(user)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: EmptyState(
            icon: Icons.work_outline,
            title: '「はたらく」を使うには\n登録が必要です',
            description: '応募・受託した案件の進捗を\nこのページで管理できます',
            actionText: '登録して始める',
            onAction: () => RegistrationPromptModal.show(context, featureName: 'はたらく機能を使う'),
          ),
        ),
      );
    }

    final uid = user!.uid;

    final tabIndex = _statusTabController.index.clamp(0, _statusTabs.length - 1);
    final selectedStatusKey = _statusTabs[tabIndex].key;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: Colors.white,
              elevation: 0,
              child: TabBar(
                controller: _statusTabController,
                isScrollable: true,
                labelColor: AppColors.ruri,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.ruri,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.ruri),
                unselectedLabelStyle: AppTextStyles.labelMedium,
                tabs: _statusTabs.map((t) => Tab(text: t.label)).toList(),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('applicantUid', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('読み込みエラー: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
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
                      title: _emptyMessageFor(selectedStatusKey),
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

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, AppSpacing.xl),
                      children: [
                        _StatusGroup(
                          title: '応募中',
                          icon: Icons.hourglass_empty,
                          color: AppColors.warning,
                          count: pending.length,
                          docs: pending,
                          onTapItem: (appId) => _navigateToDetail(context, appId),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _StatusGroup(
                          title: '承認済み（着工前・着工中）',
                          icon: Icons.check_circle_outline,
                          color: AppColors.ruri,
                          count: approved.length,
                          docs: approved,
                          onTapItem: (appId) => _navigateToDetail(context, appId),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _StatusGroup(
                          title: '完了（施工完了・検収・是正・完了）',
                          icon: Icons.done_all,
                          color: AppColors.success,
                          count: completed.length,
                          docs: completed,
                          onTapItem: (appId) => _navigateToDetail(context, appId),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
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
                            titleSnap.isNotEmpty ? titleSnap : '案件',
                            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: StatusBadge.fromStatus(statusKey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'チャット',
                                icon: const Icon(Icons.chat_bubble_outline),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatRoomPage(applicationId: applicationId),
                                    ),
                                  );
                                },
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkDetailPage(applicationId: applicationId),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
        color: Colors.white,
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
            child: Text('案件はありません', style: AppTextStyles.bodySmall),
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
                    titleSnap.isNotEmpty ? titleSnap : '案件',
                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: StatusBadge.fromStatus(statusKey),
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
