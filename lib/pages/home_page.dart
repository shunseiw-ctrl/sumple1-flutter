import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'job_list_page.dart';
import 'work_page.dart';
import 'messages_page.dart';
import 'sales_page.dart';
import 'profile_page.dart';
import 'post_page.dart';
import '../services/push_token_service.dart';
import '../core/services/auth_service.dart';
import '../core/enums/user_role.dart';
import '../core/utils/logger.dart';
import 'package:sumple1/core/constants/app_colors.dart';

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
              _isAdmin ? 'ALBAWORKS' : 'ALBAWORKS',
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            if (_isAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.ruriPale,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '管理者',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ruri,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (_index == 0 && _isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '案件を投稿',
              onPressed: _goToPost,
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '検索'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'はたらく'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'メッセージ'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: '売上'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'マイページ'),
        ],
      ),
    );
  }
}
