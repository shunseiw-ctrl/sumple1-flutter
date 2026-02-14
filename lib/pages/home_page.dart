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
    // ログイン状態が用意された後にFCMトークン同期（1回）
    Future.microtask(() => PushTokenService.syncFcmToken());
  }

  /// ユーザーロールを取得
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

  /// 管理者かどうか
  bool get _isAdmin => _userRole.isAdmin;

  late final List<Widget> _pages = const [
    JobListPage(), // 0: 検索
    WorkPage(), // 1: はたらく
    MessagesPage(), // 2: メッセージ（✅統一）
    SalesPage(), // 3: 売上
    ProfilePage(), // 4: マイページ
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
        title: Text(_isAdmin ? 'ALBAWORK（管理者）' : 'ALBAWORK'),
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
