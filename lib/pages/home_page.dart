import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';

import 'job_list_page.dart';
import 'work_page.dart';
import 'messages_page.dart';
import 'sales_page.dart';
import 'profile_page.dart';
import '../services/push_token_service.dart';
import '../core/enums/user_role.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/router/route_paths.dart';
import '../core/services/analytics_service.dart';
import '../core/providers/connectivity_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/notification_providers.dart';
import '../presentation/widgets/offline_banner.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('home');
    Future.microtask(() => PushTokenService.syncFcmToken());
  }

  bool get _isAdmin {
    final roleAsync = ref.watch(userRoleProvider);
    return roleAsync.when(
      data: (role) => role.isAdmin,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.home_greetingMorning;
    if (hour < 18) return context.l10n.home_greetingAfternoon;
    return context.l10n.home_greetingEvening;
  }

  late final List<Widget> _pages = const [
    JobListPage(),
    WorkPage(),
    MessagesPage(),
    SalesPage(),
    ProfilePage(),
  ];

  Future<void> _goToPost() async {
    await context.push(RoutePaths.postJob);
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.appColors.surface, context.appColors.background],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Semantics(
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/logo.png',
                  height: 36,
                  width: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'ALBAWORK',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_isAdmin)
                        Semantics(
                          label: context.l10n.home_statusAdmin,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.appColors.primaryPale,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.l10n.home_admin,
                                style: AppTextStyles.badgeText.copyWith(
                                  color: context.appColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final countAsync = ref.watch(unreadNotificationCountProvider);
              final count = countAsync.when(
                data: (c) => c,
                loading: () => 0,
                error: (_, __) => 0,
              );
              return Semantics(
                button: true,
                label: count > 0 ? context.l10n.home_notificationsUnread(count.toString()) : context.l10n.home_notifications(count.toString()),
                child: IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, size: 26),
                      if (count > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: context.appColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: context.l10n.home_notifications(count.toString()),
                  onPressed: () {
                    context.push(RoutePaths.notifications);
                  },
                ),
              );
            },
          ),
          if (_index == 0 && _isAdmin)
            Semantics(
              button: true,
              label: context.l10n.home_postJob,
              child: IconButton(
                icon: const Icon(Icons.add),
                tooltip: context.l10n.home_postJob,
                onPressed: _goToPost,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ModernBottomNav(
        currentIndex: _index,
        onTap: (i) {
          AppHaptics.selection();
          setState(() => _index = i);
        },
      ),
    );
  }
}

class _NavItem {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;

  const _NavItem({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
  });
}

class _ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static List<_NavItem> _items(BuildContext context) => [
    _NavItem(selectedIcon: Icons.search, unselectedIcon: Icons.search_outlined, label: context.l10n.home_navSearch),
    _NavItem(selectedIcon: Icons.work, unselectedIcon: Icons.work_outline, label: context.l10n.home_navWork),
    _NavItem(selectedIcon: Icons.chat_bubble, unselectedIcon: Icons.chat_bubble_outline, label: context.l10n.home_navMessages),
    _NavItem(selectedIcon: Icons.payments, unselectedIcon: Icons.payments_outlined, label: context.l10n.home_navSales),
    _NavItem(selectedIcon: Icons.person, unselectedIcon: Icons.person_outline, label: context.l10n.home_navProfile),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        boxShadow: [
          BoxShadow(
            color: context.appColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Row(
            children: List.generate(_items(context).length, (index) {
              final item = _items(context)[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  label: context.l10n.home_navTabLabel(item.label, isSelected ? context.l10n.home_navSelected : ''),
                  selected: isSelected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          width: isSelected ? 20 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isSelected ? context.appColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isSelected ? item.selectedIcon : item.unselectedIcon,
                          size: 26,
                          color: isSelected ? context.appColors.primary : context.appColors.textHint,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: GoogleFonts.notoSansJp(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? context.appColors.primary : context.appColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
