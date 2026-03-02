import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/qualification_model.dart';
import '../utils/logger.dart';

/// 資格管理 + 認証ワークフローサービス
class QualificationService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  QualificationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _qualificationsRef(String uid) {
    return _db
        .collection('profiles')
        .doc(uid)
        .collection('qualifications_v2');
  }

  Future<void> addQualification({
    required String name,
    required String category,
    String? certPhotoUrl,
    String? expiryDate,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('認証が必要です');

    try {
      await _qualificationsRef(uid).add({
        'uid': uid,
        'name': name,
        'category': category,
        if (certPhotoUrl != null) 'certPhotoUrl': certPhotoUrl,
        if (expiryDate != null) 'expiryDate': expiryDate,
        'verificationStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Qualification added',
          tag: 'QualificationService', data: {'name': name});
    } catch (e) {
      Logger.error('Failed to add qualification',
          tag: 'QualificationService', error: e);
      rethrow;
    }
  }

  Stream<List<QualificationModel>> watchQualifications(String uid) {
    return _qualificationsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => QualificationModel.fromFirestore(doc))
            .toList());
  }

  Future<int> getVerifiedCount(String uid) async {
    final snap = await _qualificationsRef(uid)
        .where('verificationStatus', isEqualTo: 'approved')
        .get();
    return snap.docs.length;
  }

  Future<void> approve({
    required String targetUid,
    required String qualificationId,
  }) async {
    final reviewerUid = _auth.currentUser?.uid;
    if (reviewerUid == null) throw Exception('認証が必要です');

    try {
      await _qualificationsRef(targetUid).doc(qualificationId).update({
        'verificationStatus': 'approved',
        'reviewedBy': reviewerUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Qualification approved',
          tag: 'QualificationService',
          data: {'qualificationId': qualificationId});
    } catch (e) {
      Logger.error('Failed to approve qualification',
          tag: 'QualificationService', error: e);
      rethrow;
    }
  }

  Future<void> reject({
    required String targetUid,
    required String qualificationId,
    required String reason,
  }) async {
    final reviewerUid = _auth.currentUser?.uid;
    if (reviewerUid == null) throw Exception('認証が必要です');

    try {
      await _qualificationsRef(targetUid).doc(qualificationId).update({
        'verificationStatus': 'rejected',
        'reviewedBy': reviewerUid,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Qualification rejected',
          tag: 'QualificationService',
          data: {'qualificationId': qualificationId});
    } catch (e) {
      Logger.error('Failed to reject qualification',
          tag: 'QualificationService', error: e);
      rethrow;
    }
  }
}
