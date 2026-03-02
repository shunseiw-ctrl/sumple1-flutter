import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'auth_provider.dart';

/// NotificationService プロバイダー
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// 未読通知数ストリーム
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid.isEmpty) return Stream.value(0);
  final service = ref.read(notificationServiceProvider);
  return service.unreadCountStream(uid);
});

/// 通知一覧ストリーム
final notificationsStreamProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, int>(
        (ref, limit) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('targetUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();
});
