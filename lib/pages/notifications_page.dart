import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/providers/auth_provider.dart';
import 'package:sumple1/core/providers/notification_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  static const _pageSize = 20;
  int _currentLimit = _pageSize;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('notifications');
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() {
        _currentLimit += _pageSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserUidProvider);
    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('お知らせ')),
        body: const EmptyState(
          icon: Icons.login,
          title: 'ログインが必要です',
          description: 'お知らせを表示するにはログインしてください',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('お知らせ'),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService().markAllAsRead(uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('すべて既読にしました')),
              );
            },
            child: const Text('すべて既読'),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final snapAsync = ref.watch(notificationsStreamProvider(_currentLimit));
          return snapAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('エラー: $error')),
            data: (snap) {
          final docs = snap.docs;
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'お知らせはまだありません',
              description: '新しい通知が届くとここに表示されます',
            );
          }
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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

              return Container(
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : AppColors.ruriPale,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: AppShadows.subtle,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    onTap: () {
                      if (!isRead) {
                        NotificationService().markAsRead(doc.id);
                        AnalyticsService.logNotificationOpen(type);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, color: iconColor, size: 22),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                )),
                                const SizedBox(height: AppSpacing.xs),
                                Text(body, style: AppTextStyles.bodySmall),
                                if (timeText.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(timeText, style: AppTextStyles.labelSmall),
                                ],
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.ruri,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
            },
          );
        },
      ),
    );
  }
}
