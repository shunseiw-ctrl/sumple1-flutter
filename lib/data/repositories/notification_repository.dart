import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/paginated_result.dart';
import '../../core/utils/logger.dart';

/// 通知のデータアクセスを管理
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  /// 通知一覧をページネーション付きで取得
  Future<PaginatedResult<QueryDocumentSnapshot<Map<String, dynamic>>>> getPaginated({
    required String targetUid,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('targetUid', isEqualTo: targetUid)
          .orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit + 1);

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final resultDocs = hasMore ? docs.sublist(0, limit) : docs;

      Logger.debug(
        'Fetched paginated notifications',
        tag: 'NotificationRepository',
        data: {'count': resultDocs.length, 'hasMore': hasMore},
      );

      return PaginatedResult(
        items: resultDocs,
        lastDocument: resultDocs.isNotEmpty ? resultDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get paginated notifications',
        tag: 'NotificationRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// リアルタイム通知ストリーム（最新分のみ）
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecent({
    required String targetUid,
    int limit = 20,
  }) {
    return _collection
        .where('targetUid', isEqualTo: targetUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
