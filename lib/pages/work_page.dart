import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'work_detail_page.dart';
import 'chat_room_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (!_notAnonymous(user)) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              '「はたらく」を使うにはログインが必要です\n（応募・受託した案件を表示します）',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final uid = user!.uid;

    // ✅ index 安全化
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
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.black,
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

                  final filtered = allDocs.where((d) {
                    final status = (d.data()['status'] ?? 'applied').toString();
                    if (selectedStatusKey == 'assigned') {
                      return status == 'assigned' || status == 'applied';
                    }
                    return status == selectedStatusKey;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _emptyMessageFor(selectedStatusKey),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
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
