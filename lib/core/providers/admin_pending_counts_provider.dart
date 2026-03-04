import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

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

/// 未処理件数StreamProvider（combineLatest4で並列監視）
final adminPendingCountsProvider =
    StreamProvider.autoDispose<AdminPendingCounts>((ref) {
  final db = FirebaseFirestore.instance;

  // クエリのストリーム化ヘルパー（エラー時は0を返す）
  Stream<int> countStream(Query<Map<String, dynamic>> query) {
    return query.snapshots()
        .map((snap) => snap.docs.length)
        .onErrorReturn(0);
  }

  final applicationsStream = countStream(
    db.collection('applications').where('status', isEqualTo: 'applied'),
  );

  final qualificationsStream = countStream(
    db.collectionGroup('qualifications_v2').where('verificationStatus', isEqualTo: 'pending'),
  );

  final earlyPaymentsStream = countStream(
    db.collection('early_payment_requests').where('status', isEqualTo: 'requested'),
  );

  final verificationsStream = countStream(
    db.collection('identity_verification').where('status', isEqualTo: 'pending'),
  );

  return Rx.combineLatest4(
    applicationsStream,
    qualificationsStream,
    earlyPaymentsStream,
    verificationsStream,
    (int apps, int quals, int payments, int verifications) {
      return AdminPendingCounts(
        pendingApplications: apps,
        pendingQualifications: quals,
        pendingEarlyPayments: payments,
        pendingVerifications: verifications,
      );
    },
  );
});
