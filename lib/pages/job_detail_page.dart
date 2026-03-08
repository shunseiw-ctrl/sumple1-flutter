import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';
import 'package:sumple1/core/services/favorites_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/core/services/in_app_review_service.dart';
import 'package:sumple1/core/services/share_service.dart';
import 'package:sumple1/presentation/widgets/job_placeholder_image.dart';

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
            backgroundColor: context.appColors.background,
            appBar: AppBar(
              title: Text(context.l10n.jobDetail_title, style: AppTextStyles.appBarTitle),
            ),
            body: ErrorRetryWidget.general(
              onRetry: () => context.go(RoutePaths.jobDetailPath(jobId), extra: jobData),
              message: context.l10n.common_dataLoadError,
            ),
          );
        }

        final liveDoc = snapshot.data;
        if (liveDoc == null || !liveDoc.exists) {
          return Scaffold(
            backgroundColor: context.appColors.background,
            appBar: AppBar(
              title: Text(context.l10n.jobDetail_title, style: AppTextStyles.appBarTitle),
            ),
            body: Center(child: Text(context.l10n.jobDetail_mayBeDeleted)),
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
        title: Text(context.l10n.jobDetail_deleteConfirmTitle),
        content: Text(context.l10n.jobDetail_deleteConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.common_delete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.common_deleted)));
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.l10n.jobDetail_deleteError}: $e')));
    }
  }

  Future<void> _applyToJob(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (!_notAnonymous(user)) {
      RegistrationPromptModal.show(context, featureName: context.l10n.jobDetail_applyToJob);
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
        : (data['title'] ?? title ?? context.l10n.common_job).toString();

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
        title: context.l10n.jobDetail_newApplication,
        body: context.l10n.jobDetail_applicationReceived(resolvedProjectName),
        type: 'application',
        data: {'jobId': jobId},
      );
    }

    if (!context.mounted) return;
    AppHaptics.success();
    InAppReviewService().onApplicationCompleted();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.jobDetail_snackApplied)));
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
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(context.l10n.jobDetail_title, style: AppTextStyles.appBarTitle),
        actions: [
          Builder(
            builder: (btnContext) => IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: context.l10n.jobDetail_share,
              onPressed: () async {
                final title = data['title']?.toString() ?? '';
                final price = data['price']?.toString() ?? '';
                final location = data['location']?.toString() ?? '';
                try {
                  final box = btnContext.findRenderObject() as RenderBox?;
                  final origin = box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null;
                  await ShareService.shareJob(jobId, title, price, location, origin: origin);
                  AnalyticsService.logShareJob(jobId);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${context.l10n.common_dataLoadError}: $e')),
                  );
                }
              },
            ),
          ),
          StreamBuilder<List<String>>(
            stream: _favoritesService.favoritesStream(),
            builder: (context, favSnap) {
              final isFav = _favoritesService.isRegistered
                  ? (favSnap.data ?? []).contains(jobId)
                  : _guestFavorite;

              return Semantics(
                button: true,
                label: isFav ? context.l10n.jobDetail_removeFromFavorites : context.l10n.jobDetail_addToFavorites,
                child: IconButton(
                  tooltip: context.l10n.jobDetail_favorite,
                  onPressed: () {
                    if (_favoritesService.isRegistered) {
                      _favoritesService.toggleFavorite(jobId);
                    } else {
                      setState(() {
                        _guestFavorite = !_guestFavorite;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.common_registerToSaveFavorites),
                          duration: const Duration(seconds: 2),
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
                      color: isFav ? Colors.red : context.appColors.textSecondary,
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
                    onPressed: () {
                      context.push(RoutePaths.jobEditPath(jobId), extra: data);
                    },
                    icon: Icon(Icons.edit, size: 18, color: context.appColors.textPrimary),
                    label: Text(
                      context.l10n.common_edit,
                      style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: context.l10n.jobDetail_deleteThisJob,
                    child: IconButton(
                      tooltip: context.l10n.common_delete,
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
            color: context.appColors.surface,
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
                      label: isLoading ? context.l10n.jobDetail_checkingStatus : (hasApplied ? context.l10n.jobDetail_applied : context.l10n.jobDetail_applyToThisJob),
                      enabled: enabled,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: enabled ? context.appColors.primaryGradient : null,
                          color: enabled ? null : context.appColors.divider,
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
                                SnackBar(content: Text('${context.l10n.jobDetail_applyError}: $e')),
                              );
                            }
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: context.appColors.textHint,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          child: Text(
                            isLoading ? context.l10n.jobDetail_checking : (hasApplied ? context.l10n.jobDetail_applied : context.l10n.jobDetail_applyButton),
                            style: AppTextStyles.button.copyWith(
                              color: enabled ? Colors.white : context.appColors.textHint,
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
      body: JobDetailBody(data: data, jobId: widget.jobId),
    );
  }
}

class JobDetailBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? jobId;
  const JobDetailBody({super.key, required this.data, this.jobId});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? context.l10n.common_noTitle;
    final location = data['location']?.toString() ?? context.l10n.common_notSet;
    final price = data['price']?.toString() ?? '0';
    final date = data['date']?.toString() ?? context.l10n.common_undecided;
    final imageUrl = data['imageUrl']?.toString();
    final category = data['category']?.toString();

    final description = (data['description'] ?? '').toString().trim();
    final notes = (data['notes'] ?? '').toString().trim();

    final descriptionText = description.isNotEmpty
        ? description
        : context.l10n.jobDetail_defaultDescription;

    final notesText = notes.isNotEmpty
        ? notes
        : context.l10n.jobDetail_defaultNotes;

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
                  jobId != null
                      ? Hero(
                          tag: 'hero-job-image-$jobId',
                          child: AppCachedImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: const JobPlaceholderImage(iconSize: 64),
                          ),
                        )
                      : AppCachedImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: const JobPlaceholderImage(iconSize: 64),
                        )
                else
                  const JobPlaceholderImage(iconSize: 64),
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
                          label: '${context.l10n.jobDetail_category}: $category',
                          child: StatusBadge(
                            label: category,
                            color: context.appColors.primary,
                            icon: Icons.category,
                            filled: true,
                          ),
                        ),
                      if (ownerId == null || ownerId.isEmpty)
                        Semantics(
                          label: '${context.l10n.jobDetail_status}: ${context.l10n.jobDetail_legacyData}',
                          child: StatusBadge(
                            label: context.l10n.jobDetail_legacyData,
                            color: context.appColors.warning,
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
                  Icon(Icons.place, size: 16, color: context.appColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(location, style: AppTextStyles.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              Semantics(
                label: '${context.l10n.jobDetail_paymentLabel}: ¥$price',
                child: _ModernCard(
                  color: context.appColors.primaryPale,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.appColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                        child: Icon(Icons.currency_yen, color: context.appColors.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.jobDetail_paymentLabel, style: AppTextStyles.labelMedium),
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
                    _InfoRow(icon: Icons.event, label: context.l10n.jobDetail_scheduleLabel, value: date),
                    Divider(height: AppSpacing.lg, color: context.appColors.divider),
                    _InfoRow(icon: Icons.place, label: context.l10n.jobDetail_locationLabel, value: location),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.jobDetail_jobDescription, style: AppTextStyles.headingSmall),
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
                    Text(context.l10n.jobDetail_notes, style: AppTextStyles.headingSmall),
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
        color: color ?? context.appColors.surface,
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
            color: context.appColors.primaryPale,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(icon, size: 18, color: context.appColors.primary),
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
