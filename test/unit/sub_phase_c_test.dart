import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_kpi_provider.dart';
import 'package:sumple1/core/services/notification_service.dart';

void main() {
  // === AdminKpiData: 新メトリクス getter ===
  group('AdminKpiData 拡張メトリクス', () {
    test('activeWorkerRate getter', () {
      final kpi = AdminKpiData(
        currentMonthKpi: {'activeWorkerRate': 45},
      );
      expect(kpi.activeWorkerRate, 45);
    });

    test('repeatWorkerRate getter', () {
      final kpi = AdminKpiData(
        currentMonthKpi: {'repeatWorkerRate': 30},
      );
      expect(kpi.repeatWorkerRate, 30);
    });

    test('avgJobPrice getter', () {
      final kpi = AdminKpiData(
        currentMonthKpi: {'avgJobPrice': 25000},
      );
      expect(kpi.avgJobPrice, 25000);
    });

    test('regionDistribution getter: 正常データ', () {
      final kpi = AdminKpiData(
        currentMonthKpi: {
          'regionDistribution': [
            {'name': '東京都', 'count': 50},
            {'name': '大阪府', 'count': 30},
          ],
        },
      );
      expect(kpi.regionDistribution.length, 2);
      expect(kpi.regionDistribution.first['name'], '東京都');
    });

    test('regionDistribution getter: nullの場合は空リスト', () {
      const kpi = AdminKpiData();
      expect(kpi.regionDistribution, isEmpty);
    });

    test('prevActiveWorkerRate getter', () {
      final kpi = AdminKpiData(
        previousMonthKpi: {'activeWorkerRate': 40},
      );
      expect(kpi.prevActiveWorkerRate, 40);
    });

    test('prevRepeatWorkerRate getter', () {
      final kpi = AdminKpiData(
        previousMonthKpi: {'repeatWorkerRate': 25},
      );
      expect(kpi.prevRepeatWorkerRate, 25);
    });

    test('prevAvgJobPrice getter', () {
      final kpi = AdminKpiData(
        previousMonthKpi: {'avgJobPrice': 20000},
      );
      expect(kpi.prevAvgJobPrice, 20000);
    });

    test('デフォルト値: メトリクスがnullの場合は0', () {
      const kpi = AdminKpiData();
      expect(kpi.activeWorkerRate, 0);
      expect(kpi.repeatWorkerRate, 0);
      expect(kpi.avgJobPrice, 0);
      expect(kpi.prevActiveWorkerRate, 0);
      expect(kpi.prevRepeatWorkerRate, 0);
      expect(kpi.prevAvgJobPrice, 0);
    });
  });

  // === NotificationType enum ===
  group('NotificationType', () {
    test('fromString: 既知のタイプ', () {
      expect(NotificationType.fromString('application'), NotificationType.application);
      expect(NotificationType.fromString('new_application'), NotificationType.newApplication);
      expect(NotificationType.fromString('work_report'), NotificationType.workReport);
      expect(NotificationType.fromString('inspection_failed'), NotificationType.inspectionFailed);
      expect(NotificationType.fromString('daily_summary'), NotificationType.dailySummary);
      expect(NotificationType.fromString('earning_confirmed'), NotificationType.earningConfirmed);
    });

    test('fromString: 不明タイプはgeneralにフォールバック', () {
      expect(NotificationType.fromString('unknown_type'), NotificationType.general);
      expect(NotificationType.fromString(''), NotificationType.general);
    });

    test('各タイプにアイコンと色がある', () {
      for (final type in NotificationType.values) {
        expect(type.icon, isA<IconData>());
        expect(type.color, isA<Color>());
        expect(type.value, isNotEmpty);
      }
    });

    test('全10タイプが定義されている', () {
      expect(NotificationType.values.length, 10);
    });
  });
}
