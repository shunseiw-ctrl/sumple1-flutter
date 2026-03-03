import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 管理者未処理件数
class AdminPendingCounts {
  final int pendingApplications;
  final int pendingQualifications;
  final int pendingEarlyPayments;
  final int pendingVerifications;

  const AdminPendingCounts({
    this.pendingApplications = 0,
    this.pendingQualifications = 0,
    this.pendingEarlyPayments = 0,
    this.pendingVerifications = 0,
  });

  int get total =>
      pendingApplications +
      pendingQualifications +
      pendingEarlyPayments +
      pendingVerifications;
}

/// 未処理件数StreamProvider
final adminPendingCountsProvider =
    StreamProvider.autoDispose<AdminPendingCounts>((ref) {
  final db = FirebaseFirestore.instance;

  final applicationsStream = db
      .collection('applications')
      .where('status', isEqualTo: 'applied')
      .snapshots()
      .map((snap) => snap.docs.length);

  final qualificationsStream = db
      .collectionGroup('qualifications_v2')
      .where('verificationStatus', isEqualTo: 'pending')
      .snapshots()
      .map((snap) => snap.docs.length);

  final earlyPaymentsStream = db
      .collection('early_payment_requests')
      .where('status', isEqualTo: 'requested')
      .snapshots()
      .map((snap) => snap.docs.length);

  final verificationsStream = db
      .collection('identity_verification')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snap) => snap.docs.length);

  return applicationsStream.asyncExpand((appCount) {
    return qualificationsStream.asyncExpand((qualCount) {
      return earlyPaymentsStream.asyncExpand((payCount) {
        return verificationsStream.map((verifyCount) {
          return AdminPendingCounts(
            pendingApplications: appCount,
            pendingQualifications: qualCount,
            pendingEarlyPayments: payCount,
            pendingVerifications: verifyCount,
          );
        });
      });
    });
  });
});
