import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_performance/firebase_performance.dart';

import '../models/job_model.dart';
import '../models/paginated_result.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// 案件（Job）のデータアクセスを管理
class JobRepository {
  final FirebaseFirestore _firestore;

  JobRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.collectionJobs);

  /// 案件を取得
  Future<JobModel?> getJob(String jobId) async {
    try {
      final doc = await _collection.doc(jobId).get();

      if (!doc.exists) {
        Logger.warning('Job not found', tag: 'JobRepository', data: {'jobId': jobId});
        return null;
      }

      return JobModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get job',
        tag: 'JobRepository',
        error: e,
        stackTrace: stackTrace,
        data: {'jobId': jobId},
      );
      rethrow;
    }
  }

  /// 案件をストリームで監視
  Stream<JobModel?> watchJob(String jobId) {
    return _collection.doc(jobId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return JobModel.fromFirestore(doc);
    });
  }

  /// 案件一覧を取得
  Future<List<JobModel>> getJobs({
    String? prefecture,
    String? workMonthKey,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection;

      // 都道府県でフィルター
      if (prefecture != null && prefecture != 'その他') {
        query = query.where('prefecture', isEqualTo: prefecture);
      }

      // 月でフィルター
      if (workMonthKey != null) {
        query = query.where('workMonthKey', isEqualTo: workMonthKey);
      }

      // 新着順でソート
      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();

      final jobs = snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();

      // 「その他」の場合は除外県を手動でフィルター
      if (prefecture == 'その他') {
        return jobs.where((job) {
          if (job.prefecture.isEmpty || job.prefecture == '未設定') return true;
          return !AppConstants.excludedPrefectures.contains(job.prefecture);
        }).toList();
      }

      Logger.debug(
        'Fetched jobs',
        tag: 'JobRepository',
        data: {
          'count': jobs.length,
          'prefecture': prefecture,
          'workMonthKey': workMonthKey,
        },
      );

      return jobs;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get jobs',
        tag: 'JobRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 案件一覧をストリームで監視
  Stream<List<JobModel>> watchJobs({
    String? prefecture,
    String? workMonthKey,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    // 都道府県でフィルター
    if (prefecture != null && prefecture != 'その他') {
      query = query.where('prefecture', isEqualTo: prefecture);
    }

    // 月でフィルター
    if (workMonthKey != null) {
      query = query.where('workMonthKey', isEqualTo: workMonthKey);
    }

    // 新着順でソート
    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      final jobs = snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();

      // 「その他」の場合は除外県を手動でフィルター
      if (prefecture == 'その他') {
        return jobs.where((job) {
          if (job.prefecture.isEmpty || job.prefecture == '未設定') return true;
          return !AppConstants.excludedPrefectures.contains(job.prefecture);
        }).toList();
      }

      return jobs;
    });
  }

  /// 案件を作成
  Future<String> createJob(JobModel job) async {
    try {
      final docRef = await _collection.add(job.toCreateMap());

      Logger.info(
        'Job created',
        tag: 'JobRepository',
        data: {'jobId': docRef.id, 'title': job.title},
      );

      return docRef.id;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to create job',
        tag: 'JobRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 案件を更新
  Future<void> updateJob(String jobId, JobModel job) async {
    try {
      await _collection.doc(jobId).update(job.toMap());

      Logger.info(
        'Job updated',
        tag: 'JobRepository',
        data: {'jobId': jobId, 'title': job.title},
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to update job',
        tag: 'JobRepository',
        error: e,
        stackTrace: stackTrace,
        data: {'jobId': jobId},
      );
      rethrow;
    }
  }

  /// 案件を削除
  Future<void> deleteJob(String jobId) async {
    try {
      await _collection.doc(jobId).delete();

      Logger.info(
        'Job deleted',
        tag: 'JobRepository',
        data: {'jobId': jobId},
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to delete job',
        tag: 'JobRepository',
        error: e,
        stackTrace: stackTrace,
        data: {'jobId': jobId},
      );
      rethrow;
    }
  }

  /// 案件一覧をページネーション付きで取得
  Future<PaginatedResult<JobModel>> getJobsPaginated({
    String? prefecture,
    String? workMonthKey,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Trace? trace;
    try {
      trace = FirebasePerformance.instance.newTrace('job_list_load');
      await trace.start();
    } catch (_) {
      // Performance not available (e.g., in tests)
    }
    try {
      Query<Map<String, dynamic>> query = _collection;

      if (prefecture != null && prefecture != 'その他') {
        query = query.where('prefecture', isEqualTo: prefecture);
      }

      if (workMonthKey != null) {
        query = query.where('workMonthKey', isEqualTo: workMonthKey);
      }

      query = query.orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit + 1);

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final resultDocs = hasMore ? docs.sublist(0, limit) : docs;

      var jobs = resultDocs.map((doc) => JobModel.fromFirestore(doc)).toList();

      if (prefecture == 'その他') {
        jobs = jobs.where((job) {
          if (job.prefecture.isEmpty || job.prefecture == '未設定') return true;
          return !AppConstants.excludedPrefectures.contains(job.prefecture);
        }).toList();
      }

      Logger.debug(
        'Fetched paginated jobs',
        tag: 'JobRepository',
        data: {
          'count': jobs.length,
          'hasMore': hasMore,
          'prefecture': prefecture,
          'workMonthKey': workMonthKey,
        },
      );

      try { await trace?.stop(); } catch (_) {}
      return PaginatedResult(
        items: jobs,
        lastDocument: resultDocs.isNotEmpty ? resultDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      try { await trace?.stop(); } catch (_) {}
      Logger.error(
        'Failed to get paginated jobs',
        tag: 'JobRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 特定ユーザーの案件一覧を取得
  Future<List<JobModel>> getJobsByOwner(String ownerId, {int limit = 50}) async {
    try {
      final snapshot = await _collection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final jobs = snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();

      Logger.debug(
        'Fetched jobs by owner',
        tag: 'JobRepository',
        data: {'ownerId': ownerId, 'count': jobs.length},
      );

      return jobs;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to get jobs by owner',
        tag: 'JobRepository',
        error: e,
        stackTrace: stackTrace,
        data: {'ownerId': ownerId},
      );
      rethrow;
    }
  }
}
