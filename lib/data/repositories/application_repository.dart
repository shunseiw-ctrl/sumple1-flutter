import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/paginated_result.dart';
import '../../core/utils/logger.dart';

/// 応募（Application）のデータアクセスを管理
class ApplicationRepository {
  final FirebaseFirestore _firestore;

  ApplicationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('applications');

  /// ユーザーの応募一覧をページネーション付きで取得
  Future<PaginatedResult<QueryDocumentSnapshot<Map<String, dynamic>>>> getPaginated({
    required String applicantUid,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('applicantUid', isEqualTo: applicantUid)
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
        'Fetched paginated applications',
        tag: 'ApplicationRepository',
        data: {'count': resultDocs.length, 'hasMore': hasMore},
      );

      return PaginatedResult(
        items: resultDocs,
        lastDocument: resultDocs.isNotEmpty ? resultDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get paginated applications',
        tag: 'ApplicationRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 管理者向けの応募一覧をページネーション付きで取得
  Future<PaginatedResult<QueryDocumentSnapshot<Map<String, dynamic>>>> getPaginatedByAdmin({
    required String adminUid,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('adminUid', isEqualTo: adminUid)
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
        'Fetched paginated applications (admin)',
        tag: 'ApplicationRepository',
        data: {'count': resultDocs.length, 'hasMore': hasMore},
      );

      return PaginatedResult(
        items: resultDocs,
        lastDocument: resultDocs.isNotEmpty ? resultDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get paginated applications (admin)',
        tag: 'ApplicationRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// リアルタイム応募ストリーム（最新分のみ）
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecent({
    required String applicantUid,
    int limit = 20,
  }) {
    return _collection
        .where('applicantUid', isEqualTo: applicantUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
