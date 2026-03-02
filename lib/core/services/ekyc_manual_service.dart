import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumple1/data/models/ekyc_result.dart';
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
    // Read identity_verification/{uid}.status from Firestore
    // Map: 'pending' -> EkycStatus.pending, 'approved' -> .approved, 'rejected' -> .rejected
    // If doc doesn't exist -> .notStarted
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
    // For manual verification, just return pending since the user needs to upload docs
    return const EkycPending(message: '身分証明書と顔写真をアップロードしてください');
  }
}
