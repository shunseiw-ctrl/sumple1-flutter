import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/worker_name_resolver.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late WorkerNameResolver resolver;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    resolver = WorkerNameResolver(firestore: fakeFirestore);
  });

  group('WorkerNameResolver', () {
    test('resolve_displayNameあり_displayNameを返す', () async {
      await fakeFirestore.collection('profiles').doc('uid1').set({
        'displayName': 'テスト太郎',
      });

      final name = await resolver.resolve('uid1');
      expect(name, 'テスト太郎');
    });

    test('resolve_displayNameなし_familyName+givenNameを返す', () async {
      await fakeFirestore.collection('profiles').doc('uid2').set({
        'familyName': '山田',
        'givenName': '花子',
      });

      final name = await resolver.resolve('uid2');
      expect(name, '山田 花子');
    });

    test('resolve_プロフィールなし_空文字を返す', () async {
      final name = await resolver.resolve('nonexistent');
      expect(name, '');
    });

    test('resolve_キャッシュ動作_2回目はFirestoreにアクセスしない', () async {
      await fakeFirestore.collection('profiles').doc('uid3').set({
        'displayName': 'キャッシュテスト',
      });

      final name1 = await resolver.resolve('uid3');
      final name2 = await resolver.resolve('uid3');
      expect(name1, 'キャッシュテスト');
      expect(name2, 'キャッシュテスト');
    });

    test('resolveNames_複数UID_バッチ取得成功', () async {
      await fakeFirestore.collection('profiles').doc('a1').set({'displayName': 'ユーザーA'});
      await fakeFirestore.collection('profiles').doc('a2').set({'displayName': 'ユーザーB'});
      await fakeFirestore.collection('profiles').doc('a3').set({'familyName': '佐藤'});

      final names = await resolver.resolveNames(['a1', 'a2', 'a3']);
      expect(names['a1'], 'ユーザーA');
      expect(names['a2'], 'ユーザーB');
      expect(names['a3'], '佐藤');
    });

    test('buildDisplayName_静的メソッド_正しく構築', () {
      expect(WorkerNameResolver.buildDisplayName({'displayName': 'テスト'}), 'テスト');
      expect(WorkerNameResolver.buildDisplayName({'familyName': '田中', 'givenName': '一郎'}), '田中 一郎');
      expect(WorkerNameResolver.buildDisplayName({}), '');
    });
  });
}
