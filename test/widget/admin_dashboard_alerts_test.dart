import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_pending_counts_provider.dart';

void main() {
  group('AdminDashboard アラート', () {
    test('未処理アラート: AdminPendingCounts total計算', () {
      const counts = AdminPendingCounts(
        pendingApplications: 3,
        pendingQualifications: 2,
        pendingEarlyPayments: 1,
      );

      expect(counts.total, 6);
      expect(counts.pendingApplications, 3);
      expect(counts.pendingQualifications, 2);
      expect(counts.pendingEarlyPayments, 1);
    });

    test('応募待ち件数バッジ計算', () {
      const counts = AdminPendingCounts(pendingApplications: 5);
      expect(counts.pendingApplications, 5);
    });

    test('資格承認待ち件数バッジ計算', () {
      const counts = AdminPendingCounts(pendingQualifications: 10);
      expect(counts.pendingQualifications, 10);
    });

    test('全て0の場合total=0', () {
      const counts = AdminPendingCounts();
      expect(counts.total, 0);
    });
  });
}
