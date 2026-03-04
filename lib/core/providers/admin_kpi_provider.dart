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

  int get totalJobs => (realtimeStats['totalJobs'] ?? 0) as int;
  int get totalApplications => (realtimeStats['totalApplications'] ?? 0) as int;
  int get totalUsers => (realtimeStats['totalUsers'] ?? 0) as int;
  int get pendingApplications => (realtimeStats['pendingApplications'] ?? 0) as int;

  // 月次KPI
  int get mau => (currentMonthKpi?['mau'] ?? 0) as int;
  int get monthlyEarnings => (currentMonthKpi?['monthlyEarnings'] ?? 0) as int;
  double get jobFillRate => ((currentMonthKpi?['jobFillRate'] ?? 0) as num).toDouble();

  int get prevMau => (previousMonthKpi?['mau'] ?? 0) as int;
  int get prevMonthlyEarnings => (previousMonthKpi?['monthlyEarnings'] ?? 0) as int;
  double get prevJobFillRate => ((previousMonthKpi?['jobFillRate'] ?? 0) as num).toDouble();
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
