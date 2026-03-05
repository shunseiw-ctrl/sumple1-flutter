import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/services/quality_score_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'package:sumple1/presentation/widgets/rating_stars_display.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';

class AdminWorkerDetailPage extends StatefulWidget {
  final String workerUid;
  const AdminWorkerDetailPage({super.key, required this.workerUid});

  @override
  State<AdminWorkerDetailPage> createState() => _AdminWorkerDetailPageState();
}

class _AdminWorkerDetailPageState extends State<AdminWorkerDetailPage> {
  final _db = FirebaseFirestore.instance;
  final _memoController = TextEditingController();
  bool _memoLoaded = false;
  bool _memoSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMemo();
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadMemo() async {
    try {
      final doc = await _db
          .collection('admin_memos')
          .doc(widget.workerUid)
          .get();
      if (doc.exists && mounted) {
        _memoController.text = (doc.data()?['memo'] ?? '').toString();
      }
    } catch (_) {}
    if (mounted) setState(() => _memoLoaded = true);
  }

  Future<void> _saveMemo() async {
    setState(() => _memoSaving = true);
    try {
      await _db.collection('admin_memos').doc(widget.workerUid).set({
        'memo': _memoController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      }, SetOptions(merge: true));
      if (mounted) {
        ErrorHandler.showSuccess(context, context.l10n.adminWorker_memoSaved);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e,
            customMessage: context.l10n.adminWorker_memoSaveFailed);
      }
    }
    if (mounted) setState(() => _memoSaving = false);
  }

  Future<void> _openChat() async {
    try {
      // 最新のapplicationを取得してチャットを開始
      final snap = await _db
          .collection('applications')
          .where('applicantUid', isEqualTo: widget.workerUid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        if (mounted) {
          ErrorHandler.showError(context, null,
              customMessage: context.l10n.adminWorker_noChatAvailable);
        }
        return;
      }
      if (mounted) {
        context.push(RoutePaths.chatRoomPath(snap.docs.first.id));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(context.l10n.adminWorker_title),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline,
                color: context.appColors.primary),
            tooltip: context.l10n.adminWorker_openChat,
            onPressed: _openChat,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー: プロフィール情報 + eKYCバッジ
            _buildProfileHeader(),
            const SizedBox(height: AppSpacing.xl),
            // 統計セクション
            Text(
              context.l10n.adminWorker_statistics,
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildStatistics(),
            const SizedBox(height: AppSpacing.xl),
            // 応募履歴
            Text(
              context.l10n.adminWorker_applicationHistory,
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildApplicationHistory(),
            const SizedBox(height: AppSpacing.xl),
            // 資格情報
            Text(
              context.l10n.adminWorker_qualifications,
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildQualifications(),
            const SizedBox(height: AppSpacing.xl),
            // 管理者メモ
            Text(
              context.l10n.adminWorker_memoTitle,
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildMemoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('profiles').doc(widget.workerUid).snapshots(),
      builder: (context, profileSnap) {
        if (profileSnap.hasError) {
          return ErrorRetryWidget.general(
            onRetry: () => setState(() {}),
            isCompact: true,
          );
        }
        if (!profileSnap.hasData) {
          return const SkeletonLoader(height: 80);
        }

        final data = profileSnap.data?.data();
        final familyName = (data?['familyName'] ?? '').toString().trim();
        final givenName = (data?['givenName'] ?? '').toString().trim();
        final displayName = (data?['displayName'] ?? '').toString().trim();
        final name = displayName.isNotEmpty
            ? displayName
            : (familyName.isNotEmpty || givenName.isNotEmpty)
                ? '$familyName $givenName'.trim()
                : context.l10n.adminWorker_unknownWorker;
        final avg = (data?['ratingAverage'] ?? 0).toDouble();
        final rCount = (data?['ratingCount'] as num?)?.toInt() ?? 0;
        final photoUrl = (data?['photoUrl'] ?? '').toString();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.base),
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
          child: Row(
            children: [
              // プロフィール写真
              CircleAvatar(
                radius: 32,
                backgroundColor: context.appColors.primaryPale,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Icon(Icons.person,
                        color: context.appColors.primary, size: 32)
                    : null,
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名前 + eKYCバッジ
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              style: AppTextStyles.headingSmall
                                  .copyWith(fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _EkycBadge(workerUid: widget.workerUid),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (rCount > 0)
                      RatingStarsDisplay(
                        average: avg,
                        count: rCount,
                        starSize: 16,
                        fontSize: 12,
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    _QualityScoreDisplay(uid: widget.workerUid),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatistics() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchStatistics(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SkeletonLoader(height: 80);
        }
        final stats = snap.data!;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.base),
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
          child: Row(
            children: [
              _StatCard(
                icon: Icons.check_circle_outline,
                label: context.l10n.adminWorker_statCompleted,
                value: '${stats['completed'] ?? 0}',
                color: context.appColors.success,
              ),
              _StatCard(
                icon: Icons.currency_yen,
                label: context.l10n.adminWorker_statTotalEarnings,
                value: '¥${stats['totalEarnings'] ?? 0}',
                color: context.appColors.primary,
              ),
              _StatCard(
                icon: Icons.percent,
                label: context.l10n.adminWorker_statCompletionRate,
                value: '${stats['completionRate'] ?? 0}%',
                color: context.appColors.info,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _fetchStatistics() async {
    try {
      final allApps = await _db
          .collection('applications')
          .where('applicantUid', isEqualTo: widget.workerUid)
          .get();

      final completed = allApps.docs
          .where((d) => d.data()['status'] == 'done')
          .length;
      final total = allApps.docs.length;
      final completionRate = total > 0 ? (completed * 100 ~/ total) : 0;

      // 総報酬
      int totalEarnings = 0;
      try {
        final earningsSnap = await _db
            .collection('earnings')
            .where('uid', isEqualTo: widget.workerUid)
            .get();
        for (final doc in earningsSnap.docs) {
          totalEarnings += (doc.data()['amount'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}

      return {
        'completed': completed,
        'totalEarnings': totalEarnings,
        'completionRate': completionRate,
      };
    } catch (_) {
      return {'completed': 0, 'totalEarnings': 0, 'completionRate': 0};
    }
  }

  Widget _buildApplicationHistory() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('applications')
          .where('applicantUid', isEqualTo: widget.workerUid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorRetryWidget.general(
            onRetry: () => setState(() {}),
            isCompact: true,
          );
        }
        if (!snap.hasData) {
          return SkeletonList(
              itemCount: 2,
              itemBuilder: (_) => const SkeletonWorkCard());
        }

        final allDocs = snap.data!.docs;
        if (allDocs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(context.l10n.adminWorker_noApplications,
                style: AppTextStyles.bodySmall),
          );
        }

        // ステータスグループに分類
        final inProgress = allDocs.where((d) {
          final s = (d.data()['status'] ?? '').toString();
          return s == 'assigned' || s == 'in_progress';
        }).toList();

        final completed = allDocs.where((d) {
          final s = (d.data()['status'] ?? '').toString();
          return s == 'completed' ||
              s == 'inspection' ||
              s == 'fixing' ||
              s == 'done';
        }).toList();

        final pending = allDocs.where((d) {
          final s = (d.data()['status'] ?? '').toString();
          return s == 'applied';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending.isNotEmpty)
              _WorkerApplicationGroup(
                title: context.l10n.adminApplicants_filterApplied,
                icon: Icons.hourglass_empty,
                color: context.appColors.warning,
                count: pending.length,
                docs: pending,
              ),
            if (inProgress.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _WorkerApplicationGroup(
                title: context.l10n.adminApplicants_filterInProgress,
                icon: Icons.check_circle_outline,
                color: context.appColors.primary,
                count: inProgress.length,
                docs: inProgress,
              ),
            ],
            if (completed.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _WorkerApplicationGroup(
                title: context.l10n.adminApplicants_filterDone,
                icon: Icons.done_all,
                color: context.appColors.success,
                count: completed.length,
                docs: completed,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQualifications() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('profiles')
          .doc(widget.workerUid)
          .collection('qualifications_v2')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorRetryWidget.general(
            onRetry: () => setState(() {}),
            isCompact: true,
          );
        }
        if (!snap.hasData) {
          return const SkeletonLoader(height: 40);
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(context.l10n.adminWorker_noQualifications,
                style: AppTextStyles.bodySmall),
          );
        }

        return Column(
          children: docs.asMap().entries.map((entry) {
            final data = entry.value.data();
            final name = (data['name'] ?? data['qualificationName'] ?? '')
                .toString();
            final status =
                (data['verificationStatus'] ?? 'pending').toString();
            final category = (data['category'] ?? '').toString();

            return StaggeredFadeSlide(
              index: entry.key,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000)
                          .withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined,
                        color: status == 'approved'
                            ? context.appColors.success
                            : context.appColors.textHint,
                        size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: AppTextStyles.labelLarge
                                  .copyWith(fontWeight: FontWeight.w700)),
                          if (category.isNotEmpty)
                            Text(category,
                                style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    StatusBadge.fromStatus(context, _mapVerificationStatus(status)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMemoSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_memoLoaded)
            const SkeletonLoader(height: 80)
          else
            TextField(
              controller: _memoController,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: context.l10n.adminWorker_memoHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _memoSaving ? null : _saveMemo,
              icon: _memoSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(context.l10n.adminWorker_memoSave),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mapVerificationStatus(String status) {
    switch (status) {
      case 'approved':
        return 'done';
      case 'rejected':
        return 'fixing';
      case 'pending':
      default:
        return 'applied';
    }
  }
}

// ────────────────────────────────────
// eKYCバッジ
// ────────────────────────────────────
class _EkycBadge extends StatelessWidget {
  final String workerUid;
  const _EkycBadge({required this.workerUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('identity_verification')
          .doc(workerUid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();

        final status = (snap.data!.data()?['status'] ?? 'pending').toString();

        IconData icon;
        Color color;
        String label;

        switch (status) {
          case 'approved':
            icon = Icons.verified;
            color = context.appColors.success;
            label = context.l10n.adminWorker_ekycApproved;
            break;
          case 'rejected':
            icon = Icons.cancel;
            color = context.appColors.error;
            label = context.l10n.adminWorker_ekycRejected;
            break;
          case 'pending':
          default:
            icon = Icons.hourglass_empty;
            color = context.appColors.warning;
            label = context.l10n.adminWorker_ekycPending;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(label,
                  style: AppTextStyles.badgeText.copyWith(
                      color: color, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────
// 品質スコア表示
// ────────────────────────────────────
class _QualityScoreDisplay extends StatelessWidget {
  final String uid;
  const _QualityScoreDisplay({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<WorkerQualityScore>(
      future: QualityScoreService().calculateScore(uid),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final score = snap.data!.overallScore;
        final Color bgColor;
        final Color textColor;
        if (score >= 4.0) {
          bgColor = context.appColors.success.withValues(alpha: 0.15);
          textColor = context.appColors.success;
        } else if (score >= 3.0) {
          bgColor = context.appColors.warning.withValues(alpha: 0.15);
          textColor = context.appColors.warning;
        } else {
          bgColor = context.appColors.error.withValues(alpha: 0.15);
          textColor = context.appColors.error;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            context.l10n
                .adminApplicants_qualityScore(score.toStringAsFixed(1)),
            style: AppTextStyles.badgeText.copyWith(color: textColor),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────
// 統計カード
// ────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ────────────────────────────────────
// 応募履歴グループ
// ────────────────────────────────────
class _WorkerApplicationGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _WorkerApplicationGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.docs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(title,
                  style: AppTextStyles.labelLarge
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Text('$count',
                  style: AppTextStyles.badgeText.copyWith(color: color)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...docs.asMap().entries.map((entry) {
          final data = entry.value.data();
          final titleSnap =
              (data['jobTitleSnapshot'] ?? data['projectNameSnapshot'] ?? '')
                  .toString();
          final statusKey = (data['status'] ?? 'applied').toString();
          final locationSnap =
              (data['locationSnapshot'] ?? '').toString();
          final dateSnap = (data['dateSnapshot'] ?? '').toString();

          return StaggeredFadeSlide(
            index: entry.key,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000)
                        .withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.xs),
                title: Text(
                  titleSnap.isNotEmpty
                      ? titleSnap
                      : context.l10n.common_job,
                  style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      StatusBadge.fromStatus(context, statusKey),
                      if (dateSnap.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(dateSnap, style: AppTextStyles.caption),
                      ],
                      if (locationSnap.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.place_outlined,
                            size: 12,
                            color: context.appColors.textHint),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(locationSnap,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => context
                    .push(RoutePaths.workDetailPath(entry.value.id)),
              ),
            ),
          );
        }),
      ],
    );
  }
}
