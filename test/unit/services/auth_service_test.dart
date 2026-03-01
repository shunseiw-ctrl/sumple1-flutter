import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/enums/user_role.dart';
import 'package:sumple1/core/services/auth_service.dart';

void main() {
  group('AuthService', () {
    group('isGuest', () {
      test('未ログインはゲスト', () {
        final mockAuth = MockFirebaseAuth(signedIn: false);
        final fakeFirestore = FakeFirebaseFirestore();
        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(service.isGuest, isTrue);
      });

      test('匿名ログインはゲスト', () {
        final mockUser = MockUser(isAnonymous: true, uid: 'anon-001');
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();
        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(service.isGuest, isTrue);
      });

      test('メール認証済みユーザーはゲストではない', () {
        final mockUser = MockUser(
          isAnonymous: false,
          uid: 'user-001',
          email: 'user@test.com',
        );
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();
        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(service.isGuest, isFalse);
      });
    });

    group('getCurrentUserRole', () {
      test('未ログインはguest', () async {
        final mockAuth = MockFirebaseAuth(signedIn: false);
        final fakeFirestore = FakeFirebaseFirestore();
        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);

        final role = await service.getCurrentUserRole();
        expect(role, UserRole.guest);
      });

      test('匿名ユーザーはguest', () async {
        final mockUser = MockUser(isAnonymous: true, uid: 'anon-001');
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();
        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);

        final role = await service.getCurrentUserRole();
        expect(role, UserRole.guest);
      });

      test('メール認証でadmin設定なしはuser', () async {
        final mockUser = MockUser(
          isAnonymous: false,
          uid: 'user-001',
          email: 'user@test.com',
        );
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();
        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);

        final role = await service.getCurrentUserRole();
        expect(role, UserRole.user);
      });

      test('adminUidsに含まれるユーザーはadmin', () async {
        final mockUser = MockUser(
          isAnonymous: false,
          uid: 'admin-uid-001',
          email: 'admin@test.com',
        );
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();

        // admin設定ドキュメントを作成
        await fakeFirestore.doc('config/admins').set({
          'adminUids': ['admin-uid-001'],
          'emails': [],
        });

        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);
        final role = await service.getCurrentUserRole();
        expect(role, UserRole.admin);
      });

      test('emailsに含まれるユーザーはadmin', () async {
        final mockUser = MockUser(
          isAnonymous: false,
          uid: 'user-001',
          email: 'admin@albawork.com',
        );
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();

        await fakeFirestore.doc('config/admins').set({
          'adminUids': [],
          'emails': ['admin@albawork.com'],
        });

        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);
        final role = await service.getCurrentUserRole();
        expect(role, UserRole.admin);
      });

      test('emailの大文字小文字を無視してadmin判定', () async {
        final mockUser = MockUser(
          isAnonymous: false,
          uid: 'user-001',
          email: 'ADMIN@albawork.com',
        );
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();

        await fakeFirestore.doc('config/admins').set({
          'adminUids': [],
          'emails': ['admin@albawork.com'],
        });

        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);
        final role = await service.getCurrentUserRole();
        expect(role, UserRole.admin);
      });

      test('admin設定ドキュメントが存在しなければuser', () async {
        final mockUser = MockUser(
          isAnonymous: false,
          uid: 'user-001',
          email: 'user@test.com',
        );
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();
        // config/admins を作成しない

        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);
        final role = await service.getCurrentUserRole();
        expect(role, UserRole.user);
      });
    });

    group('currentUser properties', () {
      test('currentUserIdはUID', () {
        final mockUser = MockUser(uid: 'user-001');
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        final fakeFirestore = FakeFirebaseFirestore();
        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(service.currentUserId, 'user-001');
      });

      test('未ログインのcurrentUserIdは空文字列', () {
        final mockAuth = MockFirebaseAuth(signedIn: false);
        final fakeFirestore = FakeFirebaseFirestore();
        final service = AuthService(auth: mockAuth, firestore: fakeFirestore);

        expect(service.currentUserId, '');
      });
    });
  });
}
