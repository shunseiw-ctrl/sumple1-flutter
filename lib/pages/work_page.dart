import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'work_detail_page.dart';
import 'chat_room_page.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';

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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.ruriPale,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(Icons.work_outline, size: 40, color: AppColors.ruri),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '「はたらく」を使うには\n登録が必要です',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '応募・受託した案件の進捗を\nこのページで管理できます',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => RegistrationPromptModal.show(context, featureName: 'はたらく機能を使う'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ruri,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('登録して始める', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
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
              child: TabBar(
                controller: _statusTabController,
                isScrollable: true,
                labelColor: AppColors.ruri,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.ruri,
                tabs: _statusTabs.map((t) => Tab(text: t.label)).toList(),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('applicantUid', isEqualTo: uid)
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _emptyMessageFor(selectedStatusKey),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
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
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                      children: [
                        _StatusGroup(
                          title: '応募中',
                          icon: Icons.hourglass_empty,
                          color: AppColors.warning,
                          count: pending.length,
                          docs: pending,
                          onTapItem: (appId) => _navigateToDetail(context, appId),
                        ),
                        const SizedBox(height: 16),
                        _StatusGroup(
                          title: '承認済み（着工前・着工中）',
                          icon: Icons.check_circle_outline,
                          color: AppColors.ruri,
                          count: approved.length,
                          docs: approved,
                          onTapItem: (appId) => _navigateToDetail(context, appId),
                        ),
                        const SizedBox(height: 16),
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
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text('状態: $statusKey'),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EB)),
        ),
        child: child,
      ),
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

  String _statusLabel(String key) {
    switch (key) {
      case 'applied': return '応募中';
      case 'assigned': return '着工前';
      case 'in_progress': return '着工中';
      case 'completed': return '施工完了';
      case 'inspection': return '検収中';
      case 'fixing': return '是正中';
      case 'done': return '完了';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Text('案件はありません', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
          )
        else
          ...docs.map((appDoc) {
            final app = appDoc.data();
            final titleSnap = (app['jobTitleSnapshot'] ?? app['projectNameSnapshot'] ?? '').toString();
            final statusKey = (app['status'] ?? 'applied').toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WhiteCard(
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    titleSnap.isNotEmpty ? titleSnap : '案件',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(_statusLabel(statusKey), style: TextStyle(fontSize: 12, color: color)),
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
