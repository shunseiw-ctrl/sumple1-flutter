import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sales_page.dart';
import 'profile_page.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/providers/admin_pending_counts_provider.dart';
import 'package:sumple1/pages/admin/admin_dashboard_tab.dart';
import 'package:sumple1/pages/admin/admin_job_management_tab.dart';
import 'package:sumple1/pages/admin/admin_applicants_tab.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('admin_home');
  }

  @override
  Widget build(BuildContext context) {
    final pendingCounts = ref.watch(adminPendingCountsProvider);
    final pendingApplicants = pendingCounts.valueOrNull?.pendingApplications ?? 0;

    return Scaffold(
      backgroundColor: context.appColors.background,
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
            Text(
              'ALBAWORKS',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: context.appColors.textPrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appColors.primaryPale,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.l10n.adminHome_admin,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().unreadCountStream(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: context.l10n.adminHome_notifications,
                    onPressed: () {
                      context.push(RoutePaths.notifications);
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
          AdminDashboardTab(
            onNavigateToTab: (index) => setState(() => _currentIndex = index),
          ),
          const AdminJobManagementTab(),
          const AdminApplicantsTab(),
          const SalesPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: context.appColors.primary,
        unselectedItemColor: context.appColors.textSecondary,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), activeIcon: const Icon(Icons.dashboard), label: context.l10n.adminHome_dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.work_outline), activeIcon: const Icon(Icons.work), label: context.l10n.adminHome_jobManagement),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingApplicants > 0,
              label: Text(
                pendingApplicants > 99 ? '99+' : pendingApplicants.toString(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              child: const Icon(Icons.people_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: pendingApplicants > 0,
              label: Text(
                pendingApplicants > 99 ? '99+' : pendingApplicants.toString(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              child: const Icon(Icons.people),
            ),
            label: context.l10n.adminHome_applicants,
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.payments_outlined), activeIcon: const Icon(Icons.payments), label: context.l10n.adminHome_salesManagement),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), activeIcon: const Icon(Icons.settings), label: context.l10n.adminHome_settings),
        ],
      ),
    );
  }
}
