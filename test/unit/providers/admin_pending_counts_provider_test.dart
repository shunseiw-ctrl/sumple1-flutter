import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_pending_counts_provider.dart';

void main() {
  group('AdminPendingCounts', () {
    test('デフォルト値_全て0', () {
      const counts = AdminPendingCounts();
      expect(counts.pendingApplications, 0);
      expect(counts.pendingQualifications, 0);
      expect(counts.pendingEarlyPayments, 0);
      expect(counts.pendingVerifications, 0);
      expect(counts.total, 0);
    });

    test('total_全件数の合計', () {
      const counts = AdminPendingCounts(
        pendingApplications: 5,
        pendingQualifications: 3,
        pendingEarlyPayments: 2,
        pendingVerifications: 1,
      );
      expect(counts.total, 11);
    });

    test('個別フィールド_正しく保持', () {
      const counts = AdminPendingCounts(
        pendingApplications: 10,
        pendingQualifications: 20,
      );
      expect(counts.pendingApplications, 10);
      expect(counts.pendingQualifications, 20);
      expect(counts.pendingEarlyPayments, 0);
      expect(counts.pendingVerifications, 0);
    });

    test('total_一部のみ設定', () {
      const counts = AdminPendingCounts(
        pendingApplications: 7,
      );
      expect(counts.total, 7);
    });
  });
}
