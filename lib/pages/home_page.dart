import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'job_list_page.dart';
import 'work_page.dart';
import 'messages_page.dart';
import 'sales_page.dart';
import 'profile_page.dart';
import 'post_page.dart';
import '../services/push_token_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.trim().isEmpty) return false;

    final doc = await FirebaseFirestore.instance.doc('config/admins').get();
    final data = doc.data() as Map<String, dynamic>?;
    final emails =
        (data?['emails'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return emails.contains(email);
  }

  late final List<Widget> _pages = const [
    JobListPage(),   // 0: 検索
    WorkPage(),      // 1: はたらく
    MessagesPage(),  // 2: メッセージ（✅統一）
    SalesPage(),     // 3: 売上
    ProfilePage(),   // 4: マイページ
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
        title: const Text('ALBAWORK（仮）'),
        actions: [
          if (_index == 0)
            FutureBuilder<bool>(
              future: _isAdmin(),
              builder: (context, snap) {
                final isAdmin = snap.data == true;
                if (!isAdmin) return const SizedBox.shrink();

                return IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '案件を投稿',
                  onPressed: _goToPost,
                );
              },
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
