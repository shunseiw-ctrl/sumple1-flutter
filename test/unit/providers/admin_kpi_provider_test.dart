import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_kpi_provider.dart';

void main() {
  group('AdminKpiData', () {
    test('デフォルト値_全て0', () {
      const kpi = AdminKpiData();
      expect(kpi.totalJobs, 0);
      expect(kpi.totalApplications, 0);
      expect(kpi.totalUsers, 0);
      expect(kpi.pendingApplications, 0);
      expect(kpi.mau, 0);
      expect(kpi.monthlyEarnings, 0);
      expect(kpi.jobFillRate, 0.0);
    });

    test('realtimeStats_正しく値を取得', () {
      final kpi = AdminKpiData(
        realtimeStats: {
          'totalJobs': 10,
          'totalApplications': 50,
          'totalUsers': 100,
          'pendingApplications': 5,
        },
      );
      expect(kpi.totalJobs, 10);
      expect(kpi.totalApplications, 50);
      expect(kpi.totalUsers, 100);
      expect(kpi.pendingApplications, 5);
    });

    test('月次KPI_正しく値を取得', () {
      final kpi = AdminKpiData(
        currentMonthKpi: {
          'mau': 200,
          'monthlyEarnings': 1500000,
          'jobFillRate': 0.85,
        },
      );
      expect(kpi.mau, 200);
      expect(kpi.monthlyEarnings, 1500000);
      expect(kpi.jobFillRate, 0.85);
    });

    test('前月KPI_正しく値を取得', () {
      final kpi = AdminKpiData(
        previousMonthKpi: {
          'mau': 180,
          'monthlyEarnings': 1200000,
          'jobFillRate': 0.75,
        },
      );
      expect(kpi.prevMau, 180);
      expect(kpi.prevMonthlyEarnings, 1200000);
      expect(kpi.prevJobFillRate, 0.75);
    });

    test('dailyKpi_空リスト_デフォルト', () {
      const kpi = AdminKpiData();
      expect(kpi.dailyKpi, isEmpty);
    });
  });
}
