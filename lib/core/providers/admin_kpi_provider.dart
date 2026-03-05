import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// KPIデータモデル
class AdminKpiData {
  final Map<String, dynamic> realtimeStats;
  final List<Map<String, dynamic>> dailyKpi; // 直近7日
  final Map<String, dynamic>? currentMonthKpi;
  final Map<String, dynamic>? previousMonthKpi;

  const AdminKpiData({
    this.realtimeStats = const {},
    this.dailyKpi = const [],
    this.currentMonthKpi,
    this.previousMonthKpi,
  });

  int get totalJobs => (realtimeStats['totalJobs'] as num?)?.toInt() ?? 0;
  int get totalApplications => (realtimeStats['totalApplications'] as num?)?.toInt() ?? 0;
  int get totalUsers => (realtimeStats['totalUsers'] as num?)?.toInt() ?? 0;
  int get pendingApplications => (realtimeStats['pendingApplications'] as num?)?.toInt() ?? 0;

  // 月次KPI
  int get mau => (currentMonthKpi?['mau'] as num?)?.toInt() ?? 0;
  int get monthlyEarnings => (currentMonthKpi?['monthlyEarnings'] as num?)?.toInt() ?? 0;
  double get jobFillRate => (currentMonthKpi?['jobFillRate'] as num?)?.toDouble() ?? 0.0;

  // 月次KPI拡張
  int get activeWorkerRate => (currentMonthKpi?['activeWorkerRate'] as num?)?.toInt() ?? 0;
  int get repeatWorkerRate => (currentMonthKpi?['repeatWorkerRate'] as num?)?.toInt() ?? 0;
  int get avgJobPrice => (currentMonthKpi?['avgJobPrice'] as num?)?.toInt() ?? 0;
  List<Map<String, dynamic>> get regionDistribution {
    final raw = currentMonthKpi?['regionDistribution'];
    if (raw is List) {
      return raw.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
    }
    return [];
  }

  int get prevMau => (previousMonthKpi?['mau'] as num?)?.toInt() ?? 0;
  int get prevMonthlyEarnings => (previousMonthKpi?['monthlyEarnings'] as num?)?.toInt() ?? 0;
  double get prevJobFillRate => (previousMonthKpi?['jobFillRate'] as num?)?.toDouble() ?? 0.0;
  int get prevActiveWorkerRate => (previousMonthKpi?['activeWorkerRate'] as num?)?.toInt() ?? 0;
  int get prevRepeatWorkerRate => (previousMonthKpi?['repeatWorkerRate'] as num?)?.toInt() ?? 0;
  int get prevAvgJobPrice => (previousMonthKpi?['avgJobPrice'] as num?)?.toInt() ?? 0;
}

/// KPIデータプロバイダー
final adminKpiProvider = FutureProvider.autoDispose<AdminKpiData>((ref) async {
  final db = FirebaseFirestore.instance;

  // リアルタイム統計
  final realtimeSnap = await db.doc('stats/realtime').get();
  final realtimeData = realtimeSnap.data() ?? {};

  // 直近7日分のKPI
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final startKey = '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}';

  final dailySnap = await db
      .collection('kpi_daily')
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
      .orderBy(FieldPath.documentId)
      .limit(7)
      .get();

  final dailyKpi = dailySnap.docs.map((d) => {'date': d.id, ...d.data()}).toList();

  // 当月・前月のKPI
  final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final prevMonth = DateTime(now.year, now.month - 1);
  final prevMonthKey = '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}';

  final currentMonthSnap = await db.doc('kpi_monthly/$currentMonthKey').get();
  final prevMonthSnap = await db.doc('kpi_monthly/$prevMonthKey').get();

  return AdminKpiData(
    realtimeStats: realtimeData,
    dailyKpi: dailyKpi,
    currentMonthKpi: currentMonthSnap.data(),
    previousMonthKpi: prevMonthSnap.data(),
  );
});
