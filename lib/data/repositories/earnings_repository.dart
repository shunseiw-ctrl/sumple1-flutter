import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/paginated_result.dart';
import '../../core/utils/logger.dart';

/// 売上（Earnings）のデータアクセスを管理
class EarningsRepository {
  final FirebaseFirestore _firestore;

  EarningsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('earnings');

  /// ユーザーの売上一覧をページネーション付きで取得
  Future<PaginatedResult<QueryDocumentSnapshot<Map<String, dynamic>>>> getPaginated({
    required String uid,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('uid', isEqualTo: uid)
          .orderBy('payoutConfirmedAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit + 1);

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final resultDocs = hasMore ? docs.sublist(0, limit) : docs;

      Logger.debug(
        'Fetched paginated earnings',
        tag: 'EarningsRepository',
        data: {'count': resultDocs.length, 'hasMore': hasMore},
      );

      return PaginatedResult(
        items: resultDocs,
        lastDocument: resultDocs.isNotEmpty ? resultDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get paginated earnings',
        tag: 'EarningsRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 管理者向け: 全売上をページネーション付きで取得
  Future<PaginatedResult<QueryDocumentSnapshot<Map<String, dynamic>>>> getPaginatedAll({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
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
        'Fetched paginated earnings (all)',
        tag: 'EarningsRepository',
        data: {'count': resultDocs.length, 'hasMore': hasMore},
      );

      return PaginatedResult(
        items: resultDocs,
        lastDocument: resultDocs.isNotEmpty ? resultDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get paginated earnings (all)',
        tag: 'EarningsRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// リアルタイム売上ストリーム（最新分のみ）
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecent({
    required String uid,
    int limit = 20,
  }) {
    return _collection
        .where('uid', isEqualTo: uid)
        .orderBy('payoutConfirmedAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
