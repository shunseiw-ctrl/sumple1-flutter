import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumple1/data/models/ekyc_result.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';
import 'ekyc_service.dart';

class ManualEkycService implements EkycService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ManualEkycService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  bool get isAvailable => true;

  @override
  Future<EkycStatus> checkStatus(String uid) async {
    try {
      final doc =
          await _firestore.collection('identity_verification').doc(uid).get();
      if (!doc.exists) return EkycStatus.notStarted;
      final status = (doc.data()?['status'] ?? '').toString();
      switch (status) {
        case 'pending':
          return EkycStatus.pending;
        case 'approved':
          return EkycStatus.approved;
        case 'rejected':
          return EkycStatus.rejected;
        default:
          return EkycStatus.notStarted;
      }
    } catch (_) {
      return EkycStatus.notStarted;
    }
  }

  @override
  Future<EkycResult> startVerification(String uid) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const EkycError(message: '認証が必要です');
    }
    if (user.isAnonymous) {
      return const EkycError(message: 'ゲストユーザーは本人確認を利用できません');
    }
    return const EkycPending(message: '身分証明書と顔写真をアップロードしてください');
  }

  @override
  Future<void> approve(String uid, String reviewerUid) async {
    await approveVerification(uid, reviewerUid);
  }

  @override
  Future<void> reject(String uid, String reviewerUid, String reason) async {
    await rejectVerification(uid, reviewerUid, reason);
  }

  @override
  Stream<List<IdentityVerificationModel>> getPendingStream() {
    return getPendingVerifications();
  }

  Future<void> approveVerification(String uid, String reviewerUid) async {
    final batch = _firestore.batch();
    final verifyRef = _firestore.collection('identity_verification').doc(uid);
    batch.update(verifyRef, {
      'status': 'approved',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    final profileRef = _firestore.collection('profiles').doc(uid);
    batch.update(profileRef, {
      'identityVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> rejectVerification(String uid, String reviewerUid, String reason) async {
    await _firestore.collection('identity_verification').doc(uid).update({
      'status': 'rejected',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }

  Future<IdentityVerificationModel?> getVerificationDetail(String uid) async {
    final doc = await _firestore.collection('identity_verification').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return IdentityVerificationModel.fromMap(doc.data()!);
  }

  Stream<List<IdentityVerificationModel>> getPendingVerifications() {
    return _firestore
        .collection('identity_verification')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => IdentityVerificationModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> resubmitVerification(
    String uid,
    String idPhotoUrl,
    String selfieUrl,
    String documentType,
  ) async {
    await _firestore.collection('identity_verification').doc(uid).update({
      'idPhotoUrl': idPhotoUrl,
      'selfieUrl': selfieUrl,
      'documentType': documentType,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'rejectionReason': FieldValue.delete(),
      'reviewedBy': FieldValue.delete(),
      'reviewedAt': FieldValue.delete(),
    });
  }
}
