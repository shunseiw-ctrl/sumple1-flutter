import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/activity_log_model.dart';
import '../utils/logger.dart';

/// 工程タイムラインの活動ログサービス
class ActivityLogService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ActivityLogService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const Set<String> validEventTypes = {
    'status_change',
    'checkin',
    'checkout',
    'report_submitted',
    'inspection_completed',
    'note_added',
  };

  CollectionReference<Map<String, dynamic>> _logsRef(String applicationId) {
    return _db
        .collection('applications')
        .doc(applicationId)
        .collection('activity_logs');
  }

  Future<void> logEvent({
    required String applicationId,
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('認証が必要です');

    if (!validEventTypes.contains(eventType)) {
      throw ArgumentError('無効なイベントタイプ: $eventType');
    }

    try {
      await _logsRef(applicationId).add({
        'applicationId': applicationId,
        'actorUid': uid,
        'actorRole': 'worker', // デフォルト。管理者の場合は呼び出し元で判定可能
        'eventType': eventType,
        'description': description,
        if (metadata != null) 'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Activity logged',
          tag: 'ActivityLogService',
          data: {'applicationId': applicationId, 'eventType': eventType});
    } catch (e) {
      Logger.error('Failed to log activity',
          tag: 'ActivityLogService', error: e);
      rethrow;
    }
  }

  Stream<List<ActivityLogModel>> watchTimeline(String applicationId,
      {int limit = 50}) {
    return _logsRef(applicationId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) {
              try {
                return ActivityLogModel.fromFirestore(doc);
              } catch (e) {
                Logger.error('Failed to parse activity log',
                    tag: 'ActivityLogService', error: e);
                return null;
              }
            })
            .whereType<ActivityLogModel>()
            .toList());
  }
}
