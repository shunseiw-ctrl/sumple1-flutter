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
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'おはようございます';
    if (hour < 18) return 'こんにちは';
    return 'こんばんは';
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF5F8FF)],
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_isAdmin)
                        Semantics(
                          label: 'ステータス: 管理者',
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.ruriPale,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '管理者',
                                style: AppTextStyles.badgeText.copyWith(
                                  color: AppColors.ruri,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    _greeting,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
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
                label: count > 0 ? 'お知らせ、未読$count件' : 'お知らせ',
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
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'お知らせ',
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
              label: '案件を投稿',
              child: IconButton(
                icon: const Icon(Icons.add),
                tooltip: '案件を投稿',
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

  static const List<_NavItem> _items = [
    _NavItem(selectedIcon: Icons.search, unselectedIcon: Icons.search_outlined, label: '検索'),
    _NavItem(selectedIcon: Icons.work, unselectedIcon: Icons.work_outline, label: 'はたらく'),
    _NavItem(selectedIcon: Icons.chat_bubble, unselectedIcon: Icons.chat_bubble_outline, label: 'メッセージ'),
    _NavItem(selectedIcon: Icons.payments, unselectedIcon: Icons.payments_outlined, label: '売上'),
    _NavItem(selectedIcon: Icons.person, unselectedIcon: Icons.person_outline, label: 'マイページ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  label: '${item.label}タブ${isSelected ? "、選択中" : ""}',
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
                            color: isSelected ? AppColors.ruri : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isSelected ? item.selectedIcon : item.unselectedIcon,
                          size: 26,
                          color: isSelected ? AppColors.ruri : AppColors.textHint,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: GoogleFonts.notoSansJp(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.ruri : AppColors.textHint,
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
