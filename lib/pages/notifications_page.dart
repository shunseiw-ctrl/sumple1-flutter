import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/core/services/notification_service.dart' show NotificationService, NotificationType;
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/providers/auth_provider.dart';
import 'package:sumple1/core/providers/notification_providers.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  static const _pageSize = 20;
  int _currentLimit = _pageSize;
  final _scrollController = ScrollController();
  String _filterType = 'all'; // 'all' or NotificationType.value

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
        appBar: AppBar(title: Text(context.l10n.notifications_title)),
        body: EmptyState(
          icon: Icons.login,
          title: context.l10n.notifications_loginRequired,
          description: context.l10n.notifications_loginDescription,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(context.l10n.notifications_title),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService().markAllAsRead(uid);
              AppHaptics.success();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.notifications_allRead)),
              );
            },
            child: Text(context.l10n.notifications_markAllRead),
          ),
        ],
      ),
      body: Column(
        children: [
          // フィルタチップ
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding, vertical: 8),
              children: [
                _buildFilterChip(context.l10n.notifications_filterAll, 'all'),
                const SizedBox(width: 6),
                _buildFilterChip(context.l10n.notifications_filterApplications, 'new_application'),
                const SizedBox(width: 6),
                _buildFilterChip(context.l10n.notifications_filterReports, 'work_report'),
                const SizedBox(width: 6),
                _buildFilterChip(context.l10n.notifications_filterInspections, 'inspection_failed'),
              ],
            ),
          ),
          Expanded(
        child: Consumer(
        builder: (context, ref, _) {
          final snapAsync = ref.watch(notificationsStreamProvider(_currentLimit));
          return snapAsync.when(
            loading: () => SkeletonList(itemBuilder: (_) => const SkeletonNotificationCard()),
            error: (error, _) => Center(child: Text(context.l10n.notifications_error(error.toString()))),
            data: (snap) {
          var docs = snap.docs;
          // フィルタ適用
          if (_filterType != 'all') {
            docs = docs.where((doc) {
              final type = (doc.data()['type'] ?? '').toString();
              return type == _filterType;
            }).toList();
          }
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: context.l10n.notifications_empty,
              description: context.l10n.notifications_emptyDescription,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsStreamProvider(_currentLimit));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: context.appColors.primary,
            child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            cacheExtent: AppConstants.listCacheExtent,
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

              final notifType = NotificationType.fromString(type);
              final IconData icon = notifType.icon;
              final Color iconColor = notifType.color;

              return Container(
                decoration: BoxDecoration(
                  color: isRead ? context.appColors.surface : context.appColors.primaryPale,
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
                                color: context.appColors.primary,
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
          ),
          );
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final selected = _filterType == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : context.appColors.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _filterType = type),
      selectedColor: context.appColors.primary,
      backgroundColor: context.appColors.surface,
      side: BorderSide(color: context.appColors.divider),
      visualDensity: VisualDensity.compact,
    );
  }
}
