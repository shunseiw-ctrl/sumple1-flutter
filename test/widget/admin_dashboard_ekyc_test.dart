import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_pending_counts_provider.dart';

void main() {
  group('AdminPendingCounts with verifications', () {
    test('total includes pendingVerifications', () {
      const counts = AdminPendingCounts(
        pendingApplications: 3,
        pendingQualifications: 2,
        pendingEarlyPayments: 1,
        pendingVerifications: 4,
      );
      expect(counts.total, 10);
    });

    test('default pendingVerifications is zero', () {
      const counts = AdminPendingCounts();
      expect(counts.pendingVerifications, 0);
      expect(counts.total, 0);
    });

    test('pendingVerifications field works', () {
      const counts = AdminPendingCounts(pendingVerifications: 5);
      expect(counts.pendingVerifications, 5);
      expect(counts.total, 5);
    });
  });
}
