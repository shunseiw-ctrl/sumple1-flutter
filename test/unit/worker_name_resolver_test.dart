import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/worker_name_resolver.dart';

void main() {
  group('WorkerNameResolver', () {
    late FakeFirebaseFirestore fakeFirestore;
    late WorkerNameResolver resolver;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      resolver = WorkerNameResolver(firestore: fakeFirestore);
    });

    test('resolve_プロフィールあり_名前を返す', () async {
      await fakeFirestore.collection('profiles').doc('uid1').set({
        'displayName': '田中太郎',
      });

      final name = await resolver.resolve('uid1');
      expect(name, '田中太郎');
    });

    test('resolve_プロフィールなし_空文字を返す', () async {
      final name = await resolver.resolve('unknown_uid');
      expect(name, '');
    });

    test('resolveNames_複数UIDをバッチ解決', () async {
      await fakeFirestore.collection('profiles').doc('uid1').set({
        'displayName': '田中太郎',
      });
      await fakeFirestore.collection('profiles').doc('uid2').set({
        'familyName': '佐藤',
        'givenName': '花子',
      });

      final result = await resolver.resolveNames(['uid1', 'uid2']);
      expect(result['uid1'], '田中太郎');
      expect(result['uid2'], '佐藤 花子');
    });

    test('resolveNames_キャッシュが効く', () async {
      await fakeFirestore.collection('profiles').doc('uid1').set({
        'displayName': '田中太郎',
      });

      await resolver.resolveNames(['uid1']);
      // 2回目はキャッシュから
      final result = await resolver.resolveNames(['uid1']);
      expect(result['uid1'], '田中太郎');
    });

    test('resolveProfiles_プロフィールとeKYCを取得', () async {
      await fakeFirestore.collection('profiles').doc('uid1').set({
        'displayName': 'テストユーザー',
        'photoUrl': 'https://example.com/photo.jpg',
      });
      await fakeFirestore.collection('identity_verification').doc('uid1').set({
        'status': 'approved',
      });

      final profiles = await resolver.resolveProfiles(['uid1']);
      expect(profiles['uid1']?.name, 'テストユーザー');
      expect(profiles['uid1']?.photoUrl, 'https://example.com/photo.jpg');
      expect(profiles['uid1']?.ekycStatus, 'approved');
    });

    test('resolveProfiles_eKYCなし_noneを返す', () async {
      await fakeFirestore.collection('profiles').doc('uid1').set({
        'displayName': 'テストユーザー',
      });

      final profiles = await resolver.resolveProfiles(['uid1']);
      expect(profiles['uid1']?.ekycStatus, 'none');
    });

    test('resolveProfiles_プロフィールなし_空のスナップショット', () async {
      final profiles = await resolver.resolveProfiles(['unknown_uid']);
      expect(profiles['unknown_uid']?.name, '');
      expect(profiles['unknown_uid']?.photoUrl, '');
    });

    test('clearCache_キャッシュがクリアされる', () async {
      await fakeFirestore.collection('profiles').doc('uid1').set({
        'displayName': '田中太郎',
      });

      await resolver.resolve('uid1');
      resolver.clearCache();

      // キャッシュクリア後は再度Firestoreから取得
      final name = await resolver.resolve('uid1');
      expect(name, '田中太郎');
    });

    test('buildDisplayName_displayName優先', () {
      final name = WorkerNameResolver.buildDisplayName({
        'displayName': '表示名',
        'familyName': '姓',
        'givenName': '名',
      });
      expect(name, '表示名');
    });

    test('buildDisplayName_displayNameなし_familyName+givenName', () {
      final name = WorkerNameResolver.buildDisplayName({
        'displayName': '',
        'familyName': '姓',
        'givenName': '名',
      });
      expect(name, '姓 名');
    });
  });

  group('WorkerProfileSnapshot', () {
    test('デフォルト値', () {
      const snapshot = WorkerProfileSnapshot();
      expect(snapshot.name, '');
      expect(snapshot.photoUrl, '');
      expect(snapshot.ekycStatus, 'none');
    });
  });
}
