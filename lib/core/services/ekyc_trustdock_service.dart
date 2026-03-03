import 'package:sumple1/data/models/ekyc_result.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';
import 'ekyc_service.dart';

/// TRUSTDOCK eKYC統合のスタブ実装
/// Phase 20でベンダー契約後に実装予定
class TrustdockEkycService implements EkycService {
  @override
  bool get isAvailable => false;

  @override
  Future<EkycResult> startVerification(String uid) async {
    return const EkycUnavailable();
  }

  @override
  Future<EkycStatus> checkStatus(String uid) async {
    return EkycStatus.unavailable;
  }

  @override
  Future<void> approve(String uid, String reviewerUid) async {
    throw UnimplementedError('TRUSTDOCK integration not yet available');
  }

  @override
  Future<void> reject(String uid, String reviewerUid, String reason) async {
    throw UnimplementedError('TRUSTDOCK integration not yet available');
  }

  @override
  Stream<List<IdentityVerificationModel>> getPendingStream() {
    return const Stream.empty();
  }
}
