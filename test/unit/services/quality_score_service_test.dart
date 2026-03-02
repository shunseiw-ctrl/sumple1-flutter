import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/quality_score_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late QualityScoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = QualityScoreService(firestore: fakeFirestore);
  });

  group('QualityScoreService', () {
    test('全データありの場合のスコア計算', () async {
      // 評価を追加（星4と星5）
      await fakeFirestore.collection('ratings').add({
        'targetUid': 'worker-001',
        'stars': 4,
      });
      await fakeFirestore.collection('ratings').add({
        'targetUid': 'worker-001',
        'stars': 5,
      });

      // 応募を追加（2件assigned→done, 1件in_progress）
      await fakeFirestore.collection('applications').add({
        'applicantUid': 'worker-001',
        'status': 'done',
      });
      await fakeFirestore.collection('applications').add({
        'applicantUid': 'worker-001',
        'status': 'done',
      });
      await fakeFirestore.collection('applications').add({
        'applicantUid': 'worker-001',
        'status': 'in_progress',
      });

      // 認証済み資格を追加
      await fakeFirestore
          .collection('profiles')
          .doc('worker-001')
          .collection('qualifications_v2')
          .add({
        'verificationStatus': 'approved',
      });

      final score = await service.calculateScore('worker-001');
      expect(score.ratingsAverage, 4.5);
      expect(score.ratingsCount, 2);
      expect(score.totalAssigned, 3);
      expect(score.totalCompleted, 2);
      expect(score.verifiedQualificationCount, 1);
      expect(score.overallScore, greaterThan(0));
    });

    test('評価なしの場合', () async {
      final score = await service.calculateScore('worker-002');
      expect(score.ratingsAverage, 0.0);
      expect(score.ratingsCount, 0);
      expect(score.totalAssigned, 0);
      expect(score.completionRate, 0.0);
    });

    test('完了0件の場合', () async {
      await fakeFirestore.collection('applications').add({
        'applicantUid': 'worker-003',
        'status': 'assigned',
      });

      final score = await service.calculateScore('worker-003');
      expect(score.totalAssigned, 1);
      expect(score.totalCompleted, 0);
      expect(score.completionRate, 0.0);
    });

    test('資格3件以上で満点', () {
      // 静的メソッドのテスト
      expect(WorkerQualityScore.qualificationsScore(0), 0.0);
      expect(WorkerQualityScore.qualificationsScore(1),
          closeTo(1.667, 0.01));
      expect(WorkerQualityScore.qualificationsScore(3), 5.0);
      expect(WorkerQualityScore.qualificationsScore(5), 5.0);
    });
  });
}
