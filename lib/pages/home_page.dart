import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'job_list_page.dart';
import 'work_page.dart';
import 'messages_page.dart';
import 'sales_page.dart';
import 'profile_page.dart';
import 'post_page.dart';
import '../services/push_token_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/notification_service.dart';
import '../core/enums/user_role.dart';
import '../core/utils/logger.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  int _index = 0;
  UserRole _userRole = UserRole.user;

  @override
  void initState() {
    super.initState();
    _initializeUserRole();
    Future.microtask(() => PushTokenService.syncFcmToken());
  }

  Future<void> _initializeUserRole() async {
    try {
      final role = await _authService.getCurrentUserRole();
      if (mounted) {
        setState(() => _userRole = role);
        Logger.info(
          'User role loaded',
          tag: 'HomePage',
          data: {'role': role.displayName},
        );
      }
    } catch (e) {
      Logger.error('Failed to load user role', tag: 'HomePage', error: e);
    }
  }

  bool get _isAdmin => _userRole.isAdmin;

  late final List<Widget> _pages = const [
    JobListPage(),
    WorkPage(),
    MessagesPage(),
    SalesPage(),
    ProfilePage(),
  ];

  Future<void> _goToPost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                height: 36,
                width: 36,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'ALBAWORK',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_isAdmin)
              Padding(
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
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.unreadCountStream(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return IconButton(
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
              );
            },
          ),
          if (_index == 0 && _isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '案件を投稿',
              onPressed: _goToPost,
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _ModernBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
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
            color: Colors.black.withOpacity(0.06),
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
              );
            }),
          ),
        ),
      ),
    );
  }
}
