import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'job_detail_page.dart';
import 'post_page.dart';
import 'work_detail_page.dart';
import 'sales_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/notification_service.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ALBAWORKS',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ruriPale,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '管理者',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ruri,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.unreadCountStream(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'お知らせ',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(
            onNavigateToTab: (index) => setState(() => _currentIndex = index),
          ),
          const _JobManagementTab(),
          const _ApplicantsTab(),
          const SalesPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.ruri,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'ダッシュボード'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: '案件管理'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: '応募者'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: '売上管理'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final void Function(int index) onNavigateToTab;

  const _DashboardTab({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.ruri, AppColors.ruriLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '管理者ダッシュボード',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateTime.now().year}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return _SummaryCard(
                    icon: Icons.work,
                    iconColor: AppColors.ruri,
                    iconBgColor: AppColors.ruriPale,
                    label: '掲載中の案件',
                    count: count,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('applications').snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return _SummaryCard(
                    icon: Icons.people,
                    iconColor: AppColors.success,
                    iconBgColor: const Color(0xFFD1FAE5),
                    label: '応募数',
                    count: count,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('profiles').snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return _SummaryCard(
                    icon: Icons.person,
                    iconColor: AppColors.warning,
                    iconBgColor: const Color(0xFFFEF3C7),
                    label: '登録ユーザー',
                    count: count,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('status', isEqualTo: 'applied')
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return _SummaryCard(
                    icon: Icons.pending_actions,
                    iconColor: AppColors.error,
                    iconBgColor: const Color(0xFFFEE2E2),
                    label: '未対応の応募',
                    count: count,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'クイックアクション',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_circle_outline,
                label: '案件を投稿',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PostPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.bar_chart,
                label: '売上を確認',
                onTap: () => onNavigateToTab(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '最近の応募',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('applications')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return _EmptyCard(message: 'まだ応募はありません');
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final jobTitle = (data['jobTitleSnapshot'] ?? '案件名なし').toString();
                final status = (data['status'] ?? 'applied').toString();
                final createdAt = data['createdAt'];
                String dateStr = '';
                if (createdAt is Timestamp) {
                  final d = createdAt.toDate();
                  dateStr = '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RecentApplicationCard(
                    jobTitle: jobTitle,
                    status: status,
                    dateStr: dateStr,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkDetailPage(applicationId: doc.id),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final int count;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.ruri, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentApplicationCard extends StatelessWidget {
  final String jobTitle;
  final String status;
  final String dateStr;
  final VoidCallback onTap;

  const _RecentApplicationCard({
    required this.jobTitle,
    required this.status,
    required this.dateStr,
    required this.onTap,
  });

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

  Color _statusColor(String key) {
    switch (key) {
      case 'applied':
        return AppColors.warning;
      case 'assigned':
      case 'in_progress':
        return AppColors.ruri;
      case 'completed':
      case 'done':
        return AppColors.success;
      case 'inspection':
      case 'fixing':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _JobManagementTab extends StatelessWidget {
  const _JobManagementTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('読み込みエラー: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_off_outlined, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text(
                    '案件がまだありません',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '右下のボタンから案件を投稿できます',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['title'] ?? 'タイトルなし').toString();
              final location = (data['location'] ?? '').toString();
              final price = data['price'];
              final date = (data['date'] ?? '').toString();

              return _JobCard(
                title: title,
                location: location,
                price: price is int ? price : int.tryParse(price.toString()) ?? 0,
                date: date,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailPage(jobId: doc.id, jobData: data),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostPage()),
          );
        },
        backgroundColor: AppColors.ruri,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('案件を投稿', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String title;
  final String location;
  final int price;
  final String date;
  final VoidCallback onTap;

  const _JobCard({
    required this.title,
    required this.location,
    required this.price,
    required this.date,
    required this.onTap,
  });

  String _formatPrice(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return '¥${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.ruriPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work, color: AppColors.ruri, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            location.isNotEmpty ? location : '場所未設定',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.event, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(
                          date.isNotEmpty ? date : '未定',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatPrice(price),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicantsTab extends StatefulWidget {
  const _ApplicantsTab();

  @override
  State<_ApplicantsTab> createState() => _ApplicantsTabState();
}

class _ApplicantsTabState extends State<_ApplicantsTab> {
  String _filterStatus = 'all';

  String _statusLabel(String key) {
    switch (key) {
      case 'assigned': return '着工前';
      case 'applied': return '応募中';
      case 'in_progress': return '着工中';
      case 'completed': return '施工完了';
      case 'inspection': return '検収中';
      case 'fixing': return '是正中';
      case 'done': return '完了';
      default: return key;
    }
  }

  Color _statusColor(String key) {
    switch (key) {
      case 'applied': return AppColors.warning;
      case 'assigned':
      case 'in_progress': return AppColors.ruri;
      case 'completed':
      case 'done': return AppColors.success;
      case 'inspection':
      case 'fixing': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  Future<void> _updateStatus(String appId, String newStatus, String jobTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ステータス変更'),
        content: Text('「$jobTitle」を「${_statusLabel(newStatus)}」に変更しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('変更する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('applications').doc(appId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final appDoc = await FirebaseFirestore.instance.collection('applications').doc(appId).get();
      final applicantUid = (appDoc.data()?['applicantUid'] ?? '').toString();
      if (applicantUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'targetUid': applicantUid,
          'title': 'ステータス更新',
          'body': '「$jobTitle」が「${_statusLabel(newStatus)}」になりました',
          'type': 'status_update',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$jobTitle」を${_statusLabel(newStatus)}に変更しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('変更に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'すべて'),
                _filterChip('applied', '応募中'),
                _filterChip('assigned', '着工前'),
                _filterChip('in_progress', '着工中'),
                _filterChip('done', '完了'),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('読み込みエラー: ${snap.error}'));
              }
              var docs = snap.data?.docs ?? [];

              if (_filterStatus != 'all') {
                docs = docs.where((d) {
                  final s = (d.data()['status'] ?? 'applied').toString();
                  if (_filterStatus == 'done') {
                    return s == 'completed' || s == 'inspection' || s == 'fixing' || s == 'done';
                  }
                  return s == _filterStatus;
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text(
                        _filterStatus == 'all' ? '応募者はまだいません' : '${_statusLabel(_filterStatus)}の応募はありません',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final jobTitle = (data['jobTitleSnapshot'] ?? '案件名なし').toString();
                  final status = (data['status'] ?? 'applied').toString();
                  final applicantUid = (data['applicantUid'] ?? '').toString();
                  final createdAt = data['createdAt'];
                  String dateStr = '';
                  if (createdAt is Timestamp) {
                    final d = createdAt.toDate();
                    dateStr = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                  }

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => WorkDetailPage(applicationId: doc.id),
                        ));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.ruriPale,
                                  child: const Icon(Icons.person, color: AppColors.ruri, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(jobTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text('UID: ${applicantUid.length > 8 ? '${applicantUid.substring(0, 8)}...' : applicantUid}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                          if (dateStr.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(_statusLabel(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(status))),
                                ),
                              ],
                            ),
                            if (status == 'applied') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _updateStatus(doc.id, 'rejected', jobTitle),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('却下'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: BorderSide(color: AppColors.error),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _updateStatus(doc.id, 'assigned', jobTitle),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('承認'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (status == 'assigned') ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _updateStatus(doc.id, 'in_progress', jobTitle),
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('着工開始'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ruri,
                                    side: BorderSide(color: AppColors.ruri),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                            if (status == 'in_progress') ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _updateStatus(doc.id, 'completed', jobTitle),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('施工完了'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.success,
                                    side: BorderSide(color: AppColors.success),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _filterStatus == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) => setState(() => _filterStatus = key),
        selectedColor: AppColors.ruri,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: AppColors.chipUnselected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }
}
