import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// 通知タイプ定義
enum NotificationType {
  general('general', Icons.notifications, Colors.grey),
  application('application', Icons.person_add, Colors.blue),
  statusUpdate('status_update', Icons.update, Colors.orange),
  newApplication('new_application', Icons.group_add, Colors.indigo),
  workReport('work_report', Icons.description, Colors.teal),
  inspectionFailed('inspection_failed', Icons.warning, Colors.red),
  inspectionResult('inspection_result', Icons.fact_check, Colors.deepOrange),
  dailySummary('daily_summary', Icons.summarize, Colors.purple),
  earningConfirmed('earning_confirmed', Icons.payments, Colors.green),
  verification('verification', Icons.verified_user, Colors.cyan);

  final String value;
  final IconData icon;
  final Color color;
  const NotificationType(this.value, this.icon, this.color);

  static NotificationType fromString(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => NotificationType.general,
    );
  }
}

class NotificationService {
  final FirebaseFirestore _db;

  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> createNotification({
    required String targetUid,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _db.collection('notifications').add({
        'targetUid': targetUid,
        'title': title,
        'body': body,
        'type': type ?? 'general',
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Notification created', tag: 'NotificationService', data: {'targetUid': targetUid.substring(0, targetUid.length.clamp(0, 8))});
    } catch (e) {
      Logger.error('Failed to create notification', tag: 'NotificationService', error: e);
    }
  }

  Stream<int> unreadCountStream(String uid) {
    return _db
        .collection('notifications')
        .where('targetUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('targetUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
