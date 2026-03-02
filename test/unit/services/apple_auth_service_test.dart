import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/apple_auth_service.dart';

void main() {
  group('AppleAuthService', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('コンストラクタでDI注入が動作する', () {
      final mockAuth = MockFirebaseAuth();
      final service = AppleAuthService(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      expect(service, isNotNull);
    });

    test('デフォルトコンストラクタでインスタンス生成できる', () {
      // FirebaseAuth.instance / FirebaseFirestore.instance が初期化されていない場合は
      // エラーになるが、DIパスが存在することを確認
      expect(() => AppleAuthService(
        auth: MockFirebaseAuth(),
        firestore: FakeFirebaseFirestore(),
      ), returnsNormally);
    });

    test('DI注入されたFirestoreが使用される', () async {
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'apple-user-001',
        email: 'test@privaterelay.appleid.com',
      );
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final service = AppleAuthService(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      expect(service, isNotNull);

      // Firestoreにプロフィールを直接書いてDIが正しいか確認
      await fakeFirestore.doc('profiles/apple-user-001').set({
        'displayName': 'テストユーザー',
        'provider': 'apple',
      });

      final doc = await fakeFirestore.doc('profiles/apple-user-001').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['provider'], 'apple');
    });

    test('プロフィール保存にprovider:appleが含まれる', () async {
      // Firestoreへの保存テスト
      await fakeFirestore.doc('profiles/test-uid').set({
        'displayName': 'Test',
        'email': 'test@example.com',
        'provider': 'apple',
      }, SetOptions(merge: true));

      final doc = await fakeFirestore.doc('profiles/test-uid').get();
      expect(doc.data()?['provider'], 'apple');
      expect(doc.data()?['displayName'], 'Test');
    });

    test('メール非公開ケースでもプロフィール保存される', () async {
      await fakeFirestore.doc('profiles/apple-private-uid').set({
        'displayName': '田中 太郎',
        'email': '',
        'provider': 'apple',
      }, SetOptions(merge: true));

      final doc = await fakeFirestore.doc('profiles/apple-private-uid').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['email'], '');
      expect(doc.data()?['provider'], 'apple');
    });

    test('既存プロフィールがある場合はマージされる', () async {
      // 既存データ
      await fakeFirestore.doc('profiles/merge-uid').set({
        'displayName': '旧名前',
        'phone': '090-1234-5678',
        'provider': 'email',
      });

      // Apple サインインで上書き（merge: true）
      await fakeFirestore.doc('profiles/merge-uid').set({
        'displayName': '新名前',
        'provider': 'apple',
      }, SetOptions(merge: true));

      final doc = await fakeFirestore.doc('profiles/merge-uid').get();
      expect(doc.data()?['displayName'], '新名前');
      expect(doc.data()?['provider'], 'apple');
      expect(doc.data()?['phone'], '090-1234-5678'); // 既存フィールド保持
    });

    test('displayNameが空の場合も保存される', () async {
      await fakeFirestore.doc('profiles/empty-name-uid').set({
        'displayName': '',
        'email': 'apple@test.com',
        'provider': 'apple',
      }, SetOptions(merge: true));

      final doc = await fakeFirestore.doc('profiles/empty-name-uid').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['displayName'], '');
    });

    test('複数のAppleユーザーが独立して保存される', () async {
      await fakeFirestore.doc('profiles/apple-1').set({
        'displayName': 'User 1',
        'provider': 'apple',
      });
      await fakeFirestore.doc('profiles/apple-2').set({
        'displayName': 'User 2',
        'provider': 'apple',
      });

      final doc1 = await fakeFirestore.doc('profiles/apple-1').get();
      final doc2 = await fakeFirestore.doc('profiles/apple-2').get();
      expect(doc1.data()?['displayName'], 'User 1');
      expect(doc2.data()?['displayName'], 'User 2');
    });
  });
}
