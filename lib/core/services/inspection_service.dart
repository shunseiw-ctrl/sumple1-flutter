import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/inspection_model.dart';
import '../utils/logger.dart';

/// 検査チェックリストのサービス
class InspectionService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  InspectionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _inspectionsRef(
      String applicationId) {
    return _db
        .collection('applications')
        .doc(applicationId)
        .collection('inspections');
  }

  Future<void> submitInspection({
    required String applicationId,
    required String result,
    required List<InspectionCheckItem> items,
    List<String> photoUrls = const [],
    String? overallComment,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('認証が必要です');

    try {
      await _inspectionsRef(applicationId).add({
        'applicationId': applicationId,
        'inspectorUid': uid,
        'result': result,
        'items': items.map((i) => i.toMap()).toList(),
        'photoUrls': photoUrls,
        if (overallComment != null) 'overallComment': overallComment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Inspection submitted',
          tag: 'InspectionService',
          data: {'applicationId': applicationId, 'result': result});
    } catch (e) {
      Logger.error('Failed to submit inspection',
          tag: 'InspectionService', error: e);
      rethrow;
    }
  }

  /// ジョブのカスタム検査項目を取得（なければデフォルト）
  Future<List<String>> getInspectionItems(String jobId) async {
    try {
      final doc = await _db.collection('jobs').doc(jobId).get();
      final data = doc.data();
      if (data != null && data['customInspectionItems'] is List) {
        final items = (data['customInspectionItems'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
        if (items.isNotEmpty) return items;
      }
    } catch (e) {
      Logger.error('Failed to get inspection items',
          tag: 'InspectionService', error: e);
    }
    return InspectionModel.defaultCheckItems;
  }

  Stream<InspectionModel?> watchLatestInspection(String applicationId) {
    return _inspectionsRef(applicationId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return InspectionModel.fromFirestore(snap.docs.first);
    });
  }
}
