import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/referral_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late ReferralService service;
  const testUid = 'test-user-001';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    final mockUser = MockUser(uid: testUid, isAnonymous: false);
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    service = ReferralService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('ReferralService', () {
    test('generateCode は6文字のコードを生成する', () async {
      final code = await service.generateCode(testUid);

      expect(code.length, 6);
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), isTrue);

      // Firestore にも保存されているか確認
      final doc =
          await fakeFirestore.collection('referral_codes').doc(testUid).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['code'], code);
    });

    test('generateCode は既存コードがある場合はそれを返す', () async {
      // 事前にコードを作成
      await fakeFirestore.collection('referral_codes').doc(testUid).set({
        'code': 'EXIST1',
        'uid': testUid,
        'usageCount': 0,
      });

      final code = await service.generateCode(testUid);

      expect(code, 'EXIST1');
    });

    test('applyCode は紹介ドキュメントを作成する', () async {
      const referrerUid = 'referrer-001';
      // 紹介コードを事前に作成
      await fakeFirestore.collection('referral_codes').doc(referrerUid).set({
        'code': 'REF001',
        'uid': referrerUid,
        'usageCount': 0,
      });

      await service.applyCode('REF001', testUid);

      final referrals = await fakeFirestore.collection('referrals').get();
      expect(referrals.docs.length, 1);

      final data = referrals.docs.first.data();
      expect(data['code'], 'REF001');
      expect(data['referrerUid'], referrerUid);
      expect(data['refereeUid'], testUid);
      expect(data['status'], 'pending');
      expect(data['rewardGranted'], false);
    });

    test('applyCode は自己紹介を防止する（例外をスロー）', () async {
      // 自分自身のコードを作成
      await fakeFirestore.collection('referral_codes').doc(testUid).set({
        'code': 'MYCODE',
        'uid': testUid,
        'usageCount': 0,
      });

      expect(
        () => service.applyCode('MYCODE', testUid),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('自分の紹介コードは使用できません'),
        )),
      );
    });

    test('getReferralStats は完了した紹介数を返す', () async {
      // completed な紹介を2件、pending を1件追加
      await fakeFirestore.collection('referrals').add({
        'code': 'AAA111',
        'referrerUid': testUid,
        'refereeUid': 'user-A',
        'status': 'completed',
        'rewardGranted': true,
      });
      await fakeFirestore.collection('referrals').add({
        'code': 'AAA111',
        'referrerUid': testUid,
        'refereeUid': 'user-B',
        'status': 'completed',
        'rewardGranted': true,
      });
      await fakeFirestore.collection('referrals').add({
        'code': 'AAA111',
        'referrerUid': testUid,
        'refereeUid': 'user-C',
        'status': 'pending',
        'rewardGranted': false,
      });

      final count = await service.getReferralStats(testUid);
      expect(count, 2);
    });

    test('applyCode は存在しないコードで例外をスロー', () async {
      expect(
        () => service.applyCode('NOCODE', testUid),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('紹介コードが見つかりません'),
        )),
      );
    });

    test('applyCode は未認証ユーザーで例外をスロー', () async {
      final unauthService = ReferralService(
        firestore: fakeFirestore,
        auth: MockFirebaseAuth(signedIn: false),
      );

      expect(
        () => unauthService.applyCode('ANYCODE', 'some-uid'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('ログインが必要です'),
        )),
      );
    });

    test('applyCode は重複適用を防止する', () async {
      const referrerUid = 'referrer-002';
      await fakeFirestore.collection('referral_codes').doc(referrerUid).set({
        'code': 'DUP001',
        'uid': referrerUid,
        'usageCount': 0,
      });

      // 1回目は成功
      await service.applyCode('DUP001', testUid);

      // 2回目は例外
      expect(
        () => service.applyCode('DUP001', testUid),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('このコードは既に適用済みです'),
        )),
      );
    });
  });
}
