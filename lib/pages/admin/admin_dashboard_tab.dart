import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/config/feature_flags.dart';
import 'package:sumple1/core/providers/admin_pending_counts_provider.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';

class AdminDashboardTab extends ConsumerWidget {
  final void Function(int index) onNavigateToTab;

  const AdminDashboardTab({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCounts = ref.watch(adminPendingCountsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.appColors.primary, context.appColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.adminDashboard_title,
                style: const TextStyle(
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
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.doc('stats/realtime').snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? {};
            final totalJobs = (data['totalJobs'] ?? 0) as int;
            final totalApplications = (data['totalApplications'] ?? 0) as int;
            final totalUsers = (data['totalUsers'] ?? 0) as int;
            final pendingApplications = (data['pendingApplications'] ?? 0) as int;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.work,
                        iconColor: context.appColors.primary,
                        iconBgColor: context.appColors.primaryPale,
                        label: context.l10n.adminDashboard_activeJobs,
                        count: totalJobs,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.people,
                        iconColor: context.appColors.success,
                        iconBgColor: const Color(0xFFD1FAE5),
                        label: context.l10n.adminDashboard_applicationCount,
                        count: totalApplications,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.person,
                        iconColor: context.appColors.warning,
                        iconBgColor: const Color(0xFFFEF3C7),
                        label: context.l10n.adminDashboard_registeredUsers,
                        count: totalUsers,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.pending_actions,
                        iconColor: context.appColors.error,
                        iconBgColor: const Color(0xFFFEE2E2),
                        label: context.l10n.adminDashboard_pendingApplications,
                        count: pendingApplications,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // 未処理アラートセクション
        pendingCounts.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (counts) {
            if (counts.total == 0) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.adminDashboard_pendingAlerts,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                if (counts.pendingApplications > 0)
                  _AlertCard(
                    icon: Icons.people,
                    color: context.appColors.primary,
                    label: context.l10n.adminDashboard_pendingApproval,
                    count: counts.pendingApplications,
                    onTap: () => onNavigateToTab(2),
                  ),
                if (counts.pendingQualifications > 0)
                  _AlertCard(
                    icon: Icons.workspace_premium,
                    color: context.appColors.warning,
                    label: context.l10n.adminDashboard_pendingQualifications,
                    count: counts.pendingQualifications,
                    onTap: () => context.push(RoutePaths.adminQualifications),
                  ),
                if (FeatureFlags.enableEarlyPayment && counts.pendingEarlyPayments > 0)
                  _AlertCard(
                    icon: Icons.flash_on,
                    color: Colors.orange,
                    label: context.l10n.adminDashboard_pendingEarlyPayments,
                    count: counts.pendingEarlyPayments,
                    onTap: () => context.push(RoutePaths.adminEarlyPayments),
                  ),
                if (counts.pendingVerifications > 0)
                  _AlertCard(
                    icon: Icons.verified_user,
                    color: context.appColors.info,
                    label: context.l10n.adminDashboard_pendingVerifications,
                    count: counts.pendingVerifications,
                    onTap: () => context.push(RoutePaths.adminIdentityVerification),
                  ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),

        Text(
          context.l10n.adminDashboard_quickActions,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_circle_outline,
                label: context.l10n.adminDashboard_postJob,
                onTap: () {
                  context.push(RoutePaths.postJob);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.bar_chart,
                label: context.l10n.adminDashboard_checkSales,
                onTap: () => onNavigateToTab(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.workspace_premium,
                label: context.l10n.adminDashboard_qualificationApproval,
                onTap: () {
                  context.push(RoutePaths.adminQualifications);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.verified_user,
                label: context.l10n.adminDashboard_identityVerification,
                onTap: () {
                  context.push(RoutePaths.adminIdentityVerification);
                },
              ),
            ),
            if (FeatureFlags.enableEarlyPayment) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.flash_on,
                  label: context.l10n.adminDashboard_earlyPaymentApproval,
                  onTap: () {
                    context.push(RoutePaths.adminEarlyPayments);
                  },
                ),
              ),
            ],
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.adminDashboard_recentApplications,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.appColors.textPrimary,
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
              return _EmptyCard(message: context.l10n.adminDashboard_noApplications);
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final jobTitle = (data['jobTitleSnapshot'] ?? context.l10n.adminDashboard_noJobTitle).toString();
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
                      context.push(RoutePaths.workDetailPath(doc.id));
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

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.adminDashboard_alertCount(label, count.toString()),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
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
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.appColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: context.appColors.divider),
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.appColors.textSecondary,
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
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: context.appColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: StatusBadge.colorFor(context, status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  StatusBadge.labelFor(status, context),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: StatusBadge.colorFor(context, status),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: context.appColors.textHint, size: 20),
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
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
