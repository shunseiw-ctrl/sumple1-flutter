import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'job_edit_page.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';
import 'package:sumple1/core/services/favorites_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';

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
    try { AnalyticsService.logJobView(jobId); } catch (_) {}
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
              title: Text('案件詳細', style: AppTextStyles.appBarTitle),
            ),
            body: ErrorRetryWidget.general(
              onRetry: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailPage(jobId: jobId, jobData: jobData),
                ),
              ),
              message: 'データの読み込みに失敗しました',
            ),
          );
        }

        final liveDoc = snapshot.data;
        if (liveDoc == null || !liveDoc.exists) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text('案件詳細', style: AppTextStyles.appBarTitle),
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

class _DetailScaffold extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> data;

  const _DetailScaffold({
    required this.jobId,
    required this.data,
  });

  @override
  State<_DetailScaffold> createState() => _DetailScaffoldState();
}

class _DetailScaffoldState extends State<_DetailScaffold> {
  final _favoritesService = FavoritesService();
  bool _guestFavorite = false;

  String get jobId => widget.jobId;
  Map<String, dynamic> get data => widget.data;

  bool _notAnonymous(User? u) => u != null && !u.isAnonymous;

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.trim().isEmpty) return false;

    final doc = await FirebaseFirestore.instance.doc('config/admins').get();
    final docData = doc.data();

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

    if (jobOwnerId.isNotEmpty) {
      NotificationService().createNotification(
        targetUid: jobOwnerId,
        title: '新しい応募',
        body: '$resolvedProjectNameに応募がありました',
        type: 'application',
        data: {'jobId': jobId},
      );
    }

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
        title: Text('案件詳細', style: AppTextStyles.appBarTitle),
        actions: [
          StreamBuilder<List<String>>(
            stream: _favoritesService.favoritesStream(),
            builder: (context, favSnap) {
              final isFav = _favoritesService.isRegistered
                  ? (favSnap.data ?? []).contains(jobId)
                  : _guestFavorite;

              return Semantics(
                button: true,
                label: isFav ? 'お気に入りから削除' : 'お気に入りに追加',
                child: IconButton(
                  tooltip: 'お気に入り',
                  onPressed: () {
                    if (_favoritesService.isRegistered) {
                      _favoritesService.toggleFavorite(jobId);
                    } else {
                      setState(() {
                        _guestFavorite = !_guestFavorite;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('登録するとお気に入りが保存されます'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey<bool>(isFav),
                      color: isFav ? Colors.red : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
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
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                    label: const Text(
                      '編集',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'この案件を削除',
                    child: IconButton(
                      tooltip: '削除',
                      onPressed: () => _deleteJob(context),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppShadows.bottomNav,
          ),
          child: FutureBuilder<bool>(
            future: _hasApplied(),
            builder: (context, snap) {
              final hasApplied = snap.data == true;
              final isLoading = snap.connectionState == ConnectionState.waiting;

              final enabled = !isLoading && !hasApplied;

              return Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: isLoading ? '応募状況を確認中' : (hasApplied ? '応募済み' : 'この案件に応募する'),
                      enabled: enabled,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: enabled ? AppColors.primaryGradient : null,
                          color: enabled ? null : AppColors.divider,
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          boxShadow: enabled ? AppShadows.button : [],
                        ),
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
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: AppColors.textHint,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          child: Text(
                            isLoading ? '確認中...' : (hasApplied ? '応募済み' : '応募する'),
                            style: AppTextStyles.button.copyWith(
                              color: enabled ? Colors.white : AppColors.textHint,
                            ),
                          ),
                        ),
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
    final imageUrl = data['imageUrl']?.toString();
    final category = data['category']?.toString();

    final description = (data['description'] ?? '').toString().trim();
    final notes = (data['notes'] ?? '').toString().trim();

    final descriptionText = description.isNotEmpty
        ? description
        : '・現場作業の補助\n・資材運搬／清掃\n・指示に従って作業\n\n※ここは次フェーズでFirestoreのdescriptionに置き換え';

    final notesText = notes.isNotEmpty
        ? notes
        : '・遅刻／無断欠勤は評価に影響します\n・安全靴／作業着推奨\n・詳細はチャットで確認してください';

    final ownerId = data['ownerId']?.toString();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppSpacing.cardRadiusLg),
            bottomRight: Radius.circular(AppSpacing.cardRadiusLg),
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  AppCachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: _buildGradientPlaceholder(),
                  )
                else
                  _buildGradientPlaceholder(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 80,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.base,
                  bottom: AppSpacing.md,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (category != null && category.isNotEmpty)
                        Semantics(
                          label: 'カテゴリ: $category',
                          child: StatusBadge(
                            label: category,
                            color: AppColors.ruri,
                            icon: Icons.category,
                            filled: true,
                          ),
                        ),
                      if (ownerId == null || ownerId.isEmpty)
                        Semantics(
                          label: 'ステータス: 旧データ',
                          child: const StatusBadge(
                            label: '旧データ',
                            color: AppColors.warning,
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.base,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(location, style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              Semantics(
                label: '報酬: ¥$price',
                child: _ModernCard(
                  color: AppColors.ruriPale,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.ruri.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                        child: const Icon(Icons.currency_yen, color: AppColors.ruri, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('報酬', style: AppTextStyles.labelMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text('¥$price', style: AppTextStyles.salaryLarge),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ModernCard(
                child: Column(
                  children: [
                    _InfoRow(icon: Icons.event, label: '日程', value: date),
                    const Divider(height: AppSpacing.lg, color: AppColors.divider),
                    _InfoRow(icon: Icons.place, label: '場所', value: location),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('仕事内容', style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(descriptionText, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('注意事項', style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(notesText, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientPlaceholder() {
    return Semantics(
      excludeSemantics: true,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.ruriPale,
              Color(0xFFD0DFFA),
              Color(0xFFBDD0F5),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.construction,
            size: 64,
            color: AppColors.ruri.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _ModernCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: child,
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.ruriPale,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(icon, size: 18, color: AppColors.ruri),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 44,
          child: Text(label, style: AppTextStyles.labelMedium),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(value, style: AppTextStyles.labelLarge),
        ),
      ],
    );
  }
}
