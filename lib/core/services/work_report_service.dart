import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/work_report_model.dart';
import '../utils/logger.dart';

/// 日報（WorkReport）の CRUD サービス
class WorkReportService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  WorkReportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _reportsRef(
      String applicationId) {
    return _db
        .collection('applications')
        .doc(applicationId)
        .collection('work_reports');
  }

  Future<void> createReport({
    required String applicationId,
    required String reportDate,
    required String workContent,
    required double hoursWorked,
    List<String> photoUrls = const [],
    String? notes,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('認証が必要です');

    try {
      await _reportsRef(applicationId).add({
        'applicationId': applicationId,
        'workerUid': uid,
        'reportDate': reportDate,
        'workContent': workContent,
        'hoursWorked': hoursWorked,
        'photoUrls': photoUrls,
        if (notes != null) 'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Work report created',
          tag: 'WorkReportService',
          data: {'applicationId': applicationId, 'reportDate': reportDate});
    } catch (e) {
      Logger.error('Failed to create work report',
          tag: 'WorkReportService', error: e);
      rethrow;
    }
  }

  Stream<List<WorkReportModel>> watchReports(String applicationId) {
    return _reportsRef(applicationId)
        .orderBy('reportDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WorkReportModel.fromFirestore(doc))
            .toList());
  }

  Future<int> getReportCount(String applicationId) async {
    final snap = await _reportsRef(applicationId).get();
    return snap.docs.length;
  }
}
