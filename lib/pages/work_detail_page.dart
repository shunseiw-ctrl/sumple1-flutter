import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_room_page.dart';
import 'job_detail_page.dart'; // ★ JobDetailBody を使うため追加

class WorkDetailPage extends StatefulWidget {
  final String applicationId;
  const WorkDetailPage({super.key, required this.applicationId});

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _notAnonymous(User? u) => u != null && !u.isAnonymous;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _statusLabel(String key) {
    switch (key) {
      case 'assigned':
        return '着工前';
      case 'applied':
        return '応募中';
      case 'in_progress':
        return '着工中';
      case 'completed':
        return '施工完了';
      case 'inspection':
        return '検収中';
      case 'fixing':
        return '是正中';
      case 'done':
        return '完了';
      default:
        return key;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(widget.applicationId)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (!_notAnonymous(user)) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('「はたらく」を使うにはログインが必要です'),
          ),
        ),
      );
    }

    final uid = user!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('読み込みエラー: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final doc = snap.data!;
        if (!doc.exists) {
          return const Scaffold(body: Center(child: Text('この案件は存在しません')));
        }

        final app = doc.data() ?? <String, dynamic>{};

        final applicantUid = (app['applicantUid'] ?? '').toString();
        if (applicantUid.isNotEmpty && applicantUid != uid) {
          return const Scaffold(body: Center(child: Text('権限がありません')));
        }

        final title = (app['jobTitleSnapshot'] ?? '案件').toString();
        final status = (app['status'] ?? 'applied').toString();

        final canStart = status == 'assigned' || status == 'applied';
        final canComplete = status == 'in_progress';

        // ★ 重要：jobs を引くための jobId（無いと概要を揃えられない）
        final jobId = (app['jobId'] ?? '').toString();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F5F7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              title,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'チャット',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(applicationId: widget.applicationId),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: '概要'),
                Tab(text: '写真'),
                Tab(text: '資料'),
              ],
            ),
          ),
          body: Column(
            children: [
              // ===== 赤線より上（このUIは維持）=====
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1F4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: canStart
                          ? () async {
                        try {
                          await _updateStatus('in_progress');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('開始しました（着工中）')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('開始に失敗: $e')),
                          );
                        }
                      }
                          : null,
                      child: const Text('開始'),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: canComplete
                          ? () async {
                        try {
                          await _updateStatus('completed');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('完了しました（施工完了）')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('完了に失敗: $e')),
                          );
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('完了'),
                    ),
                  ],
                ),
              ),

              // ===== 赤線より下（タブ中身）=====
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(app: app, jobId: jobId), // ★ここが差し替え点
                    const _PhotosTab(),
                    const _DocsTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> app;
  final String jobId;

  const _OverviewTab({required this.app, required this.jobId});

  @override
  Widget build(BuildContext context) {
    // jobId が無い旧データ対策（最低限のフォールバック）
    if (jobId.trim().isEmpty) {
      final title = (app['jobTitleSnapshot'] ?? '').toString();
      final location = (app['jobLocationSnapshot'] ?? '').toString();
      final price = (app['jobPriceSnapshot'] ?? '').toString();
      final date = (app['jobDateSnapshot'] ?? '').toString();

      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('概要', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                Text('案件名: ${title.isNotEmpty ? title : "-"}'),
                Text('場所: ${location.isNotEmpty ? location : "-"}'),
                Text('報酬: ${price.isNotEmpty ? price : "-"}'),
                Text('日程: ${date.isNotEmpty ? date : "未定"}'),
                const SizedBox(height: 12),
                const Text(
                  '※jobIdが無いデータのため、詳細本文を表示できません',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ★ここが「検索の案件詳細と同じ本文」にする肝
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(jobId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('読み込みエラー: ${snap.error}'));
        }
        final doc = snap.data;
        if (doc == null || !doc.exists) {
          return const Center(child: Text('案件が見つかりません'));
        }

        final jobData = doc.data() ?? <String, dynamic>{};

        // ✅ 赤線より下が検索の「案件詳細」と一致（JobDetailBodyのUIを使い回す）
        return JobDetailBody(data: jobData);
      },
    );
  }
}

class _PhotosTab extends StatelessWidget {
  const _PhotosTab();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('写真（準備中）\nここにアップロード・一覧を入れる', textAlign: TextAlign.center),
    );
  }
}

class _DocsTab extends StatelessWidget {
  const _DocsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('資料（準備中）', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              SizedBox(height: 8),
              Text('・御見積書（0）'),
              Text('・図面（0）'),
              Text('・仕様（0）'),
              Text('・工程（0）'),
              SizedBox(height: 8),
              Text('KANNA風にフォルダ分け＋追加ボタンを実装予定', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

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
