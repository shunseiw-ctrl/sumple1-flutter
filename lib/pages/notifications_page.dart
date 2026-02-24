import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('お知らせ')),
        body: const Center(child: Text('ログインが必要です')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('お知らせ'),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService.markAllAsRead(uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('すべて既読にしました')),
              );
            },
            child: const Text('すべて既読'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('targetUid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('エラー: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('お知らせはまだありません', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final title = (data['title'] ?? '').toString();
              final body = (data['body'] ?? '').toString();
              final isRead = data['read'] == true;
              final type = (data['type'] ?? '').toString();
              final createdAt = data['createdAt'];
              String timeText = '';
              if (createdAt is Timestamp) {
                final dt = createdAt.toDate();
                timeText = '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              IconData icon;
              Color iconColor;
              switch (type) {
                case 'application':
                  icon = Icons.person_add;
                  iconColor = AppColors.ruri;
                  break;
                case 'status_update':
                  icon = Icons.update;
                  iconColor = Colors.orange;
                  break;
                default:
                  icon = Icons.notifications;
                  iconColor = AppColors.textSecondary;
              }

              return Material(
                color: isRead ? Colors.white : AppColors.ruriPale,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (!isRead) {
                      NotificationService.markAsRead(doc.id);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                color: AppColors.textPrimary,
                              )),
                              const SizedBox(height: 4),
                              Text(body, style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              )),
                              if (timeText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(timeText, style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                )),
                              ],
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.ruri,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
