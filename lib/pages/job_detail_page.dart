import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'job_edit_page.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';

class JobDetailPage extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobDetailPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(jobId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _DetailScaffold(jobId: jobId, data: jobData);
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                '案件詳細',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
            body: Center(child: Text('読み込みエラー: ${snapshot.error}')),
          );
        }

        final liveDoc = snapshot.data;
        if (liveDoc == null || !liveDoc.exists) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                '案件詳細',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
            body: const Center(child: Text('この案件は削除された可能性があります')),
          );
        }

        final data = liveDoc.data() ?? <String, dynamic>{};
        return _DetailScaffold(jobId: jobId, data: data);
      },
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> data;

  const _DetailScaffold({
    required this.jobId,
    required this.data,
  });

  bool _notAnonymous(User? u) => u != null && !u.isAnonymous;

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.trim().isEmpty) return false;

    final doc = await FirebaseFirestore.instance.doc('config/admins').get();
    final docData = doc.data() as Map<String, dynamic>?;

    final adminUids = (docData?['adminUids'] as List?)
            ?.map((e) => e.toString().trim())
            .toList() ??
        [];
    if (adminUids.contains(user?.uid)) return true;

    final adminEmails = (docData?['emails'] as List?)
            ?.map((e) => e.toString().toLowerCase().trim())
            .toList() ??
        [];
    return adminEmails.contains(email.toLowerCase().trim());
  }

  Future<void> _deleteJob(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この案件を削除すると元に戻せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除しました')));
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
    }
  }

  Future<void> _applyToJob(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (!_notAnonymous(user)) {
      RegistrationPromptModal.show(context, featureName: '案件に応募する');
      return;
    }

    final uid = user!.uid;

    final title = data['title']?.toString().trim();
    final location = data['location']?.toString().trim();
    final price = data['price']?.toString().trim();
    final date = data['date']?.toString().trim();

    final projectNameSnapshot = (data['projectName'] ?? '').toString().trim();
    final resolvedProjectName = projectNameSnapshot.isNotEmpty
        ? projectNameSnapshot
        : (data['title'] ?? title ?? '案件').toString();

    final jobOwnerId = (data['ownerId'] ?? data['adminUid'] ?? data['createdBy'] ?? '').toString();
    await FirebaseFirestore.instance.collection('applications').add({
      'applicantUid': uid,
      'adminUid': jobOwnerId,
      'jobId': jobId,

      'projectNameSnapshot': resolvedProjectName,

      'jobTitleSnapshot': (title != null && title.isNotEmpty) ? title : resolvedProjectName,
      'jobLocationSnapshot': (location != null && location.isNotEmpty) ? location : '',
      'jobPriceSnapshot': (price != null && price.isNotEmpty) ? price : '',
      'jobDateSnapshot': (date != null && date.isNotEmpty) ? date : '',

      'status': 'applied',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('応募しました')));
  }

  Future<bool> _hasApplied() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!_notAnonymous(user)) return false;

    final uid = user!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('applications')
        .where('applicantUid', isEqualTo: uid)
        .limit(50)
        .get();

    return snap.docs.any((d) {
      final m = d.data();
      return (m['jobId'] ?? '').toString() == jobId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '案件詳細',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          FutureBuilder<bool>(
            future: _isAdmin(),
            builder: (context, snap) {
              final isAdmin = snap.data == true;
              if (!isAdmin) return const SizedBox.shrink();

              return Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobEditPage(jobId: jobId, jobData: data),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                    label: Text(
                      '編集',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: '削除',
                    onPressed: () => _deleteJob(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          color: Colors.white,
          child: FutureBuilder<bool>(
            future: _hasApplied(),
            builder: (context, snap) {
              final hasApplied = snap.data == true;
              final isLoading = snap.connectionState == ConnectionState.waiting;

              final enabled = !isLoading && !hasApplied;

              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: enabled
                          ? () async {
                        try {
                          await _applyToJob(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('応募に失敗しました: $e')),
                          );
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: enabled ? AppColors.ruri : AppColors.ruri.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isLoading ? '確認中...' : (hasApplied ? '応募済み' : '応募する'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: JobDetailBody(data: data),
    );
  }
}

class JobDetailBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const JobDetailBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'タイトルなし';
    final location = data['location']?.toString() ?? '未設定';
    final price = data['price']?.toString() ?? '0';
    final date = data['date']?.toString() ?? '未定';

    final description = (data['description'] ?? '').toString().trim();
    final notes = (data['notes'] ?? '').toString().trim();

    final descriptionText = description.isNotEmpty
        ? description
        : '・現場作業の補助\n・資材運搬／清掃\n・指示に従って作業\n\n※ここは次フェーズでFirestoreのdescriptionに置き換え';

    final notesText = notes.isNotEmpty
        ? notes
        : '・遅刻／無断欠勤は評価に影響します\n・安全靴／作業着推奨\n・詳細はチャットで確認してください';

    final ownerId = data['ownerId']?.toString();
    final badges = <_BadgeSpec>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      children: [
        _WhiteCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.photo, color: AppColors.textHint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final b in badges)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: b.bg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              b.label,
                              style: TextStyle(
                                color: b.fg,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (ownerId == null || ownerId.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '旧データ',
                              style: TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      location,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _WhiteCard(
          child: Row(
            children: [
              Icon(Icons.currency_yen, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              const Text('報酬', style: TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                '¥$price',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _WhiteCard(
          child: Column(
            children: [
              _InfoRow(icon: Icons.event, label: '日程', value: date),
              const Divider(height: 18),
              _InfoRow(icon: Icons.place, label: '場所', value: location),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('仕事内容', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              Text(descriptionText, style: TextStyle(color: AppColors.textPrimary, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('注意事項', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              Text(notesText, style: TextStyle(color: AppColors.textPrimary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeSpec {
  final String label;
  final Color bg;
  final Color fg;
  const _BadgeSpec({required this.label, required this.bg, required this.fg});
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
