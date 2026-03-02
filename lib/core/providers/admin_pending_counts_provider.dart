import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 管理者未処理件数
class AdminPendingCounts {
  final int pendingApplications;
  final int pendingQualifications;
  final int pendingEarlyPayments;

  const AdminPendingCounts({
    this.pendingApplications = 0,
    this.pendingQualifications = 0,
    this.pendingEarlyPayments = 0,
  });

  int get total => pendingApplications + pendingQualifications + pendingEarlyPayments;
}

/// 未処理件数StreamProvider
final adminPendingCountsProvider = StreamProvider.autoDispose<AdminPendingCounts>((ref) {
  final db = FirebaseFirestore.instance;

  // 応募待ち数
  final applicationsStream = db
      .collection('applications')
      .where('status', isEqualTo: 'applied')
      .snapshots()
      .map((snap) => snap.docs.length);

  // 資格承認待ち数（全profilesのqualifications_v2をカウント）
  // ベータ規模ではコレクショングループクエリを使用
  final qualificationsStream = db
      .collectionGroup('qualifications_v2')
      .where('verificationStatus', isEqualTo: 'pending')
      .snapshots()
      .map((snap) => snap.docs.length);

  // 即金申請待ち数
  final earlyPaymentsStream = db
      .collection('early_payment_requests')
      .where('status', isEqualTo: 'requested')
      .snapshots()
      .map((snap) => snap.docs.length);

  // 3つのストリームを結合
  return applicationsStream.asyncExpand((appCount) {
    return qualificationsStream.asyncExpand((qualCount) {
      return earlyPaymentsStream.map((payCount) {
        return AdminPendingCounts(
          pendingApplications: appCount,
          pendingQualifications: qualCount,
          pendingEarlyPayments: payCount,
        );
      });
    });
  });
});
