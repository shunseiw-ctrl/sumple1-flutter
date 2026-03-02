import 'package:cloud_firestore/cloud_firestore.dart';

/// ワーカー品質スコア
class WorkerQualityScore {
  final double ratingsAverage; // 0.0-5.0
  final int ratingsCount;
  final double completionRate; // 0.0-1.0
  final int totalAssigned;
  final int totalCompleted;
  final int verifiedQualificationCount;
  final double overallScore;

  WorkerQualityScore({
    required this.ratingsAverage,
    required this.ratingsCount,
    required this.completionRate,
    required this.totalAssigned,
    required this.totalCompleted,
    required this.verifiedQualificationCount,
    required this.overallScore,
  });

  /// 資格スコア: 3資格以上で満点（5.0）
  static double qualificationsScore(int count) {
    if (count <= 0) return 0.0;
    return (count / 3.0).clamp(0.0, 1.0) * 5.0;
  }

  /// 総合スコア計算: ratings*0.5 + completion*0.3 + qualifications*0.2
  static double calculateOverall({
    required double ratingsAverage,
    required double completionRate,
    required int verifiedQualificationCount,
  }) {
    final ratingsPart = ratingsAverage * 0.5;
    final completionPart = completionRate * 5.0 * 0.3;
    final qualPart = qualificationsScore(verifiedQualificationCount) * 0.2;
    return ratingsPart + completionPart + qualPart;
  }
}

/// 品質スコア計算サービス（オンデマンド）
class QualityScoreService {
  final FirebaseFirestore _db;

  QualityScoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<WorkerQualityScore> calculateScore(String workerUid) async {
    // 1. 評価を取得
    final ratingsSnap = await _db
        .collection('ratings')
        .where('targetUid', isEqualTo: workerUid)
        .get();

    double ratingsAverage = 0.0;
    final ratingsCount = ratingsSnap.docs.length;
    if (ratingsCount > 0) {
      final totalStars = ratingsSnap.docs.fold<int>(
        0,
        (acc, doc) => acc + ((doc.data()['stars'] as int?) ?? 0),
      );
      ratingsAverage = totalStars / ratingsCount;
    }

    // 2. 完了率を計算
    final assignedSnap = await _db
        .collection('applications')
        .where('applicantUid', isEqualTo: workerUid)
        .where('status', whereIn: ['assigned', 'in_progress', 'completed', 'done'])
        .get();
    final totalAssigned = assignedSnap.docs.length;

    final completedSnap = await _db
        .collection('applications')
        .where('applicantUid', isEqualTo: workerUid)
        .where('status', isEqualTo: 'done')
        .get();
    final totalCompleted = completedSnap.docs.length;

    final completionRate =
        totalAssigned > 0 ? totalCompleted / totalAssigned : 0.0;

    // 3. 認証済み資格数
    final qualSnap = await _db
        .collection('profiles')
        .doc(workerUid)
        .collection('qualifications_v2')
        .where('verificationStatus', isEqualTo: 'approved')
        .get();
    final verifiedCount = qualSnap.docs.length;

    // 4. 総合スコア
    final overallScore = WorkerQualityScore.calculateOverall(
      ratingsAverage: ratingsAverage,
      completionRate: completionRate,
      verifiedQualificationCount: verifiedCount,
    );

    return WorkerQualityScore(
      ratingsAverage: ratingsAverage,
      ratingsCount: ratingsCount,
      completionRate: completionRate,
      totalAssigned: totalAssigned,
      totalCompleted: totalCompleted,
      verifiedQualificationCount: verifiedCount,
      overallScore: overallScore,
    );
  }
}
