import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_applicants_provider.dart';
import 'package:sumple1/core/services/worker_name_resolver.dart';

void main() {
  group('ApplicantItem', () {
    test('copyWith_全フィールド更新', () {
      const item = ApplicantItem(
        id: '1',
        jobTitle: 'テスト案件',
        status: 'applied',
        applicantUid: 'uid1',
      );

      final updated = item.copyWith(
        workerName: '田中太郎',
        photoUrl: 'https://example.com/photo.jpg',
        verifiedQualificationCount: 3,
        completedJobCount: 5,
        ekycStatus: 'approved',
      );

      expect(updated.id, '1');
      expect(updated.jobTitle, 'テスト案件');
      expect(updated.workerName, '田中太郎');
      expect(updated.photoUrl, 'https://example.com/photo.jpg');
      expect(updated.verifiedQualificationCount, 3);
      expect(updated.completedJobCount, 5);
      expect(updated.ekycStatus, 'approved');
    });

    test('copyWith_部分更新_他フィールド維持', () {
      const item = ApplicantItem(
        id: '1',
        jobTitle: 'テスト案件',
        status: 'applied',
        applicantUid: 'uid1',
        workerName: '既存名前',
        ratingAverage: 4.5,
        ratingCount: 10,
      );

      final updated = item.copyWith(workerName: '新名前');

      expect(updated.workerName, '新名前');
      expect(updated.ratingAverage, 4.5);
      expect(updated.ratingCount, 10);
      expect(updated.jobTitle, 'テスト案件');
    });

    test('デフォルト値_新フィールドが正しい', () {
      const item = ApplicantItem(
        id: '1',
        jobTitle: 'テスト',
        status: 'applied',
        applicantUid: 'uid1',
      );

      expect(item.photoUrl, '');
      expect(item.verifiedQualificationCount, 0);
      expect(item.completedJobCount, 0);
      expect(item.ekycStatus, 'none');
    });
  });

  group('AdminApplicantsNotifier データ変換', () {
    late FakeFirebaseFirestore fakeFirestore;
    late WorkerNameResolver resolver;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      resolver = WorkerNameResolver(firestore: fakeFirestore);
    });

    test('プロフィールデータが存在する場合、名前がフォールバック解決される', () async {
      // テスト用プロフィールを作成
      await fakeFirestore.collection('profiles').doc('worker1').set({
        'displayName': '鈴木一郎',
        'photoUrl': 'https://example.com/suzuki.jpg',
      });

      // eKYC情報
      await fakeFirestore.collection('identity_verification').doc('worker1').set({
        'status': 'approved',
      });

      // resolveProfilesで取得
      final profiles = await resolver.resolveProfiles(['worker1']);
      expect(profiles['worker1']?.name, '鈴木一郎');
      expect(profiles['worker1']?.photoUrl, 'https://example.com/suzuki.jpg');
      expect(profiles['worker1']?.ekycStatus, 'approved');
    });
  });
}
