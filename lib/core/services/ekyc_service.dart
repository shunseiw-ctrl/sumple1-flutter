import 'package:sumple1/data/models/ekyc_result.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';

abstract class EkycService {
  Future<EkycResult> startVerification(String uid);
  Future<EkycStatus> checkStatus(String uid);
  bool get isAvailable;

  Future<void> approve(String uid, String reviewerUid);
  Future<void> reject(String uid, String reviewerUid, String reason);
  Stream<List<IdentityVerificationModel>> getPendingStream();
}
