import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/presentation/widgets/rating_dialog.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/config/feature_flags.dart';
import 'package:sumple1/core/providers/connectivity_provider.dart';
import 'package:sumple1/presentation/widgets/offline_banner.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';

import 'job_detail_page.dart' show JobDetailBody;
import 'work_detail/photos_tab.dart';
import 'work_detail/docs_tab.dart';
import 'work_detail/work_reports_tab.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/core/services/work_report_service.dart';

class WorkDetailPage extends ConsumerStatefulWidget {
  final String applicationId;
  const WorkDetailPage({super.key, required this.applicationId});

  @override
  ConsumerState<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends ConsumerState<WorkDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _notAnonymous(User? u) => u != null && !u.isAnonymous;

  bool _isAdminUser = false;

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.trim().isEmpty) {
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.doc('config/admins').get();
      final data = doc.data();
      final emails = (data?['emails'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final adminUids = (data?['adminUids'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (mounted) {
        setState(() {
          _isAdminUser = emails.contains(email) || adminUids.contains(user?.uid);
        });
      }
    } catch (e) {
      Logger.warning('管理者チェックに失敗', tag: 'WorkDetail', data: {'error': '$e'});
    }
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('work_detail');
    _tabController = TabController(length: 4, vsync: this);
    _checkAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(context.l10n.workDetail_loginRequired),
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
          return Scaffold(body: Center(child: Text('${context.l10n.common_loadError}: ${snap.error}')));
        }
        if (!snap.hasData) {
          return Scaffold(body: SkeletonList(itemBuilder: (_) => const SkeletonWorkCard()));
        }
        final doc = snap.data!;
        if (!doc.exists) {
          return Scaffold(body: Center(child: Text(context.l10n.workDetail_jobNotFound)));
        }

        final app = doc.data() ?? <String, dynamic>{};

        final applicantUid = (app['applicantUid'] ?? '').toString();
        if (applicantUid.isNotEmpty && applicantUid != uid && !_isAdminUser) {
          return Scaffold(body: Center(child: Text(context.l10n.workDetail_noPermission)));
        }

        final title = (app['jobTitleSnapshot'] ?? context.l10n.common_job).toString();
        final status = (app['status'] ?? 'applied').toString();

        final canStart = status == 'assigned' || status == 'applied';
        final canComplete = status == 'in_progress';

        final jobId = (app['jobId'] ?? '').toString();

        return Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            title: Text(
              title,
              style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: context.l10n.workDetail_timeline,
                icon: const Icon(Icons.timeline),
                onPressed: () {
                  context.push(RoutePaths.workTimelinePath(widget.applicationId));
                },
              ),
              if (_isAdminUser && jobId.isNotEmpty)
                IconButton(
                  tooltip: context.l10n.workDetail_qrAttendance,
                  icon: const Icon(Icons.qr_code),
                  onPressed: () {
                    context.push(RoutePaths.shiftQrPath(jobId), extra: {
                      'jobTitle': title,
                    });
                  },
                ),
              IconButton(
                tooltip: context.l10n.workDetail_chat,
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  context.push(RoutePaths.chatRoomPath(widget.applicationId));
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: context.appColors.primary,
              unselectedLabelColor: context.appColors.textSecondary,
              indicatorColor: context.appColors.primary,
              tabs: [
                Tab(text: context.l10n.workDetail_tabOverview),
                Tab(text: context.l10n.workDetail_tabDailyReport),
                Tab(text: context.l10n.workDetail_tabPhotos),
                Tab(text: context.l10n.workDetail_tabDocuments),
              ],
            ),
          ),
          body: Column(
            children: [
              if (!ref.watch(isOnlineProvider)) const OfflineBanner(),
              Container(
                color: context.appColors.surface,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.appColors.borderLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        StatusBadge.labelFor(status, context),
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
                            NotificationService().createNotification(
                              targetUid: applicantUid,
                              title: context.l10n.workDetail_statusUpdate,
                              body: context.l10n.workDetail_statusInProgress(title),
                              type: 'status_update',
                            );
                          }
                          if (!context.mounted) return;
                          AppHaptics.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.workDetail_snackStarted)),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${context.l10n.workDetail_snackStartError}: $e')),
                          );
                        }
                      }
                          : null,
                      child: Text(context.l10n.workDetail_startButton),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: canComplete
                          ? () async {
                        try {
                          // 完了ゲート: 日報1件以上
                          final reportCount = await WorkReportService()
                              .getReportCount(widget.applicationId);
                          if (reportCount == 0) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.workDetail_reportRequired)),
                            );
                            return;
                          }
                          await _updateStatus('completed');
                          final applicantUid = (app['applicantUid'] ?? '').toString();
                          if (applicantUid.isNotEmpty) {
                            NotificationService().createNotification(
                              targetUid: applicantUid,
                              title: context.l10n.workDetail_statusUpdate,
                              body: context.l10n.workDetail_statusCompleted(title),
                              type: 'status_update',
                            );
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.workDetail_snackCompleted)),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${context.l10n.workDetail_snackCompleteError}: $e')),
                          );
                        }
                      }
                          : null,
                      child: Text(context.l10n.workDetail_completeButton),
                    ),
                    // 管理者: 検収ボタン
                    if (_isAdminUser && (status == 'completed' || status == 'fixing'))
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push(RoutePaths.workInspectionPath(widget.applicationId));
                          },
                          icon: const Icon(Icons.checklist, size: 18),
                          label: Text(status == 'fixing' ? context.l10n.workDetail_reinspect : context.l10n.workDetail_startInspection),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    if (status == 'done' && _isAdminUser)
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
                                  const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(context.l10n.workDetail_rated, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
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
                                targetUid: applicantUid,
                              );
                            },
                            icon: const Icon(Icons.star_rounded, size: 18),
                            label: Text(context.l10n.workDetail_rateButton),
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
                Divider(height: 1, color: context.appColors.divider),
              if (status == 'in_progress' || status == 'assigned')
                Container(
                  color: context.appColors.surface,
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
                            color: isCheckedIn ? Colors.green : context.appColors.textHint,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCheckedOut
                                ? context.l10n.workDetail_checkedOut
                                : isCheckedIn
                                    ? context.l10n.workDetail_checkedIn
                                    : context.l10n.workDetail_notCheckedIn,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isCheckedIn ? Colors.green : context.appColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (!isCheckedIn && !isCheckedOut)
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push(RoutePaths.qrCheckinPath(widget.applicationId), extra: {
                                  'isCheckOut': false,
                                });
                              },
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: Text(context.l10n.workDetail_qrClockIn),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          if (isCheckedIn && !isCheckedOut)
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push(RoutePaths.qrCheckinPath(widget.applicationId), extra: {
                                  'isCheckOut': true,
                                });
                              },
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: Text(context.l10n.workDetail_qrClockOut),
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
                                color: context.appColors.chipUnselected,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(context.l10n.common_completed, style: TextStyle(fontWeight: FontWeight.w700, color: context.appColors.textSecondary)),
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
                    _OverviewTab(app: app, jobId: jobId, applicationId: widget.applicationId),
                    WorkReportsTab(applicationId: widget.applicationId),
                    WorkPhotosTab(applicationId: widget.applicationId, jobId: jobId),
                    WorkDocsTab(applicationId: widget.applicationId),
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
  final String applicationId;

  const _OverviewTab({required this.app, required this.jobId, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final status = (app['status'] ?? '').toString();
    final showPayment = ['completed', 'done', 'inspection', 'fixing'].contains(status);

    if (jobId.trim().isEmpty) {
      final title = (app['jobTitleSnapshot'] ?? '').toString();
      final location = (app['jobLocationSnapshot'] ?? '').toString();
      final price = (app['jobPriceSnapshot'] ?? '').toString();
      final date = (app['jobDateSnapshot'] ?? '').toString();

      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (showPayment && FeatureFlags.enableStripePayments) ...[
            _PaymentInfoCard(applicationId: applicationId),
            const SizedBox(height: 12),
          ],
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.workDetail_tabOverview, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                Text('${context.l10n.workDetail_jobName}: ${title.isNotEmpty ? title : "-"}'),
                Text('${context.l10n.workDetail_location}: ${location.isNotEmpty ? location : "-"}'),
                Text('${context.l10n.workDetail_payment}: ${price.isNotEmpty ? price : "-"}'),
                Text('${context.l10n.workDetail_schedule}: ${date.isNotEmpty ? date : context.l10n.common_undecided}'),
                const SizedBox(height: 12),
                Text(
                  context.l10n.workDetail_noJobIdWarning,
                  style: TextStyle(color: context.appColors.textSecondary),
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
          return Center(child: Text('${context.l10n.common_loadError}: ${snap.error}'));
        }
        final doc = snap.data;
        if (doc == null || !doc.exists) {
          return Center(child: Text(context.l10n.workDetail_jobNotFound));
        }

        final jobData = doc.data() ?? <String, dynamic>{};

        if (showPayment && FeatureFlags.enableStripePayments) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _PaymentInfoCard(applicationId: applicationId),
              ),
              JobDetailBody(data: jobData),
            ],
          );
        }

        return JobDetailBody(data: jobData);
      },
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  final String applicationId;
  const _PaymentInfoCard({required this.applicationId});

  String _formatYen(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return '¥${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('earnings')
          .where('applicationId', isEqualTo: applicationId)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final docs = snap.data?.docs ?? [];

        Widget content;
        VoidCallback? onTap;

        if (docs.isEmpty) {
          // 未確定
          content = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.payments_outlined, size: 22, color: context.appColors.textHint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.workDetail_payment, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(context.l10n.workDetail_paymentUnconfirmed, style: TextStyle(color: context.appColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ],
          );
        } else {
          final data = docs.first.data();
          final amount = (data['amount'] is int) ? (data['amount'] as int) : 0;
          final paymentStatus = (data['paymentStatus'] ?? '').toString();
          final paymentId = (data['paymentId'] ?? '').toString();
          final isSucceeded = paymentStatus == 'succeeded' || paymentStatus == 'paid';

          final statusLabel = isSucceeded ? context.l10n.common_transferred : context.l10n.common_confirmed;
          final statusColor = isSucceeded ? context.appColors.success : context.appColors.primary;
          final iconBgColor = isSucceeded ? context.appColors.success.withValues(alpha: 0.15) : context.appColors.primary.withValues(alpha: 0.15);

          if (paymentId.isNotEmpty) {
            onTap = () {
              context.push(RoutePaths.paymentDetailPath(paymentId));
            };
          }

          content = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSucceeded ? Icons.check_circle : Icons.account_balance_wallet,
                  size: 22,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      _formatYen(amount),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: statusColor),
                    ),
                  ],
                ),
              ),
              if (paymentId.isNotEmpty)
                Icon(Icons.chevron_right, color: statusColor, size: 22),
            ],
          );
        }

        return Material(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.appColors.border),
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.divider),
        ),
        child: child,
      ),
    );
  }
}
