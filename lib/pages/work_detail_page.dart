import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_room_page.dart';
import 'job_detail_page.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/presentation/widgets/rating_dialog.dart';
import 'package:sumple1/core/services/notification_service.dart';

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

  Future<bool> _hasRated(String applicationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await FirebaseFirestore.instance
        .collection('ratings')
        .where('applicationId', isEqualTo: applicationId)
        .where('raterUid', isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> _checkIn() async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .update({
        'checkInAt': FieldValue.serverTimestamp(),
        'checkInStatus': 'checked_in',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('出勤しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('出勤記録に失敗: $e')),
      );
    }
  }

  Future<void> _checkOut() async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .update({
        'checkOutAt': FieldValue.serverTimestamp(),
        'checkInStatus': 'checked_out',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退勤しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退勤記録に失敗: $e')),
      );
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

        final jobId = (app['jobId'] ?? '').toString();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              title,
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
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
              labelColor: AppColors.ruri,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.ruri,
              tabs: const [
                Tab(text: '概要'),
                Tab(text: '写真'),
                Tab(text: '資料'),
              ],
            ),
          ),
          body: Column(
            children: [
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
                          final applicantUid = (app['applicantUid'] ?? '').toString();
                          if (applicantUid.isNotEmpty) {
                            NotificationService.createNotification(
                              targetUid: applicantUid,
                              title: 'ステータス更新',
                              body: '${title}が「着工中」になりました',
                              type: 'status_update',
                            );
                          }
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
                          final applicantUid = (app['applicantUid'] ?? '').toString();
                          if (applicantUid.isNotEmpty) {
                            NotificationService.createNotification(
                              targetUid: applicantUid,
                              title: 'ステータス更新',
                              body: '${title}が「施工完了」になりました',
                              type: 'status_update',
                            );
                          }
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
                      child: const Text('完了'),
                    ),
                    const SizedBox(width: 6),
                    if (status == 'done')
                      FutureBuilder<bool>(
                        future: _hasRated(widget.applicationId),
                        builder: (context, ratingSnap) {
                          final hasRated = ratingSnap.data == true;
                          if (hasRated) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text('評価済み', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                                ],
                              ),
                            );
                          }
                          return ElevatedButton.icon(
                            onPressed: () {
                              RatingDialog.show(
                                context,
                                applicationId: widget.applicationId,
                                jobId: jobId,
                                jobTitle: title,
                              );
                            },
                            icon: const Icon(Icons.star_rounded, size: 18),
                            label: const Text('評価する'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              if (status == 'in_progress' || status == 'assigned')
                Divider(height: 1, color: AppColors.divider),
              if (status == 'in_progress' || status == 'assigned')
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Builder(
                    builder: (context) {
                      final checkInStatus = (app['checkInStatus'] ?? '').toString();
                      final isCheckedIn = checkInStatus == 'checked_in';
                      final isCheckedOut = checkInStatus == 'checked_out';

                      return Row(
                        children: [
                          Icon(
                            isCheckedIn ? Icons.location_on : Icons.location_off_outlined,
                            color: isCheckedIn ? Colors.green : AppColors.textHint,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCheckedOut
                                ? '退勤済み'
                                : isCheckedIn
                                    ? '出勤中'
                                    : '未出勤',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isCheckedIn ? Colors.green : AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (!isCheckedIn && !isCheckedOut)
                            ElevatedButton.icon(
                              onPressed: () => _checkIn(),
                              icon: const Icon(Icons.login, size: 18),
                              label: const Text('出勤'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          if (isCheckedIn && !isCheckedOut)
                            ElevatedButton.icon(
                              onPressed: () => _checkOut(),
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('退勤'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          if (isCheckedOut)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.chipUnselected,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text('完了', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(app: app, jobId: jobId),
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
                Text(
                  '※jobIdが無いデータのため、詳細本文を表示できません',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

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
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('資料（準備中）', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('・御見積書（0）'),
              const Text('・図面（0）'),
              const Text('・仕様（0）'),
              const Text('・工程（0）'),
              const SizedBox(height: 8),
              Text('KANNA風にフォルダ分け＋追加ボタンを実装予定', style: TextStyle(color: AppColors.textSecondary)),
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
