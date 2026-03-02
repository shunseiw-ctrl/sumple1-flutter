import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/favorites_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late FavoritesService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'test-user-1'),
    );
    service = FavoritesService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('fetchJobsByIds', () {
    test('空リストで空Map返却', () async {
      final result = await service.fetchJobsByIds([]);
      expect(result, isEmpty);
    });

    test('単一jobId取得', () async {
      await fakeFirestore.collection('jobs').doc('job1').set({
        'title': 'テスト案件1',
        'location': '東京都',
      });

      final result = await service.fetchJobsByIds(['job1']);
      expect(result.length, 1);
      expect(result['job1']?['title'], 'テスト案件1');
    });

    test('複数jobId取得', () async {
      await fakeFirestore.collection('jobs').doc('job1').set({'title': '案件1'});
      await fakeFirestore.collection('jobs').doc('job2').set({'title': '案件2'});
      await fakeFirestore.collection('jobs').doc('job3').set({'title': '案件3'});

      final result = await service.fetchJobsByIds(['job1', 'job2', 'job3']);
      expect(result.length, 3);
      expect(result['job1']?['title'], '案件1');
      expect(result['job2']?['title'], '案件2');
      expect(result['job3']?['title'], '案件3');
    });

    test('存在しないID含む場合の部分取得', () async {
      await fakeFirestore.collection('jobs').doc('job1').set({'title': '案件1'});

      final result = await service.fetchJobsByIds(['job1', 'nonexistent']);
      expect(result.length, 1);
      expect(result['job1']?['title'], '案件1');
      expect(result.containsKey('nonexistent'), isFalse);
    });

    test('30件超のバッチ分割動作', () async {
      final ids = <String>[];
      for (var i = 0; i < 35; i++) {
        final id = 'job_$i';
        ids.add(id);
        await fakeFirestore.collection('jobs').doc(id).set({'title': 'Job $i'});
      }

      final result = await service.fetchJobsByIds(ids);
      expect(result.length, 35);
      expect(result['job_0']?['title'], 'Job 0');
      expect(result['job_34']?['title'], 'Job 34');
    });

    test('全ID不存在時に空Map返却', () async {
      final result = await service.fetchJobsByIds(['missing1', 'missing2']);
      expect(result, isEmpty);
    });
  });
}
