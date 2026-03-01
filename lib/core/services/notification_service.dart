import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

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
