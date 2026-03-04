import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/services/quality_score_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(context.l10n.adminWorker_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー: プロフィール情報
            _buildProfileHeader(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('profiles').doc(widget.workerUid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorRetryWidget.general(
            onRetry: () => setState(() {}),
            isCompact: true,
          );
        }
        if (!snap.hasData) {
          return const SkeletonLoader(height: 80);
        }

        final data = snap.data?.data();
        final familyName = (data?['familyName'] ?? '').toString().trim();
        final givenName = (data?['givenName'] ?? '').toString().trim();
        final displayName = (data?['displayName'] ?? '').toString().trim();
        final name = displayName.isNotEmpty
            ? displayName
            : (familyName.isNotEmpty || givenName.isNotEmpty)
                ? '$familyName $givenName'.trim()
                : context.l10n.adminWorker_unknownWorker;
        final avg = (data?['ratingAverage'] ?? 0).toDouble();
        final rCount = (data?['ratingCount'] ?? 0) as int;

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
              CircleAvatar(
                radius: 32,
                backgroundColor: context.appColors.primaryPale,
                child: Icon(Icons.person,
                    color: context.appColors.primary, size: 32),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.headingSmall
                            .copyWith(fontWeight: FontWeight.w800)),
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
