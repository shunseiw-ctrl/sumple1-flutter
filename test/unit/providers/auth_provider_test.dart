import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/auth_provider.dart';
import 'package:sumple1/core/services/auth_service.dart';

void main() {
  group('authServiceProvider', () {
    test('オーバーライドでカスタムAuthServiceを返す', () {
      final mockAuth = MockFirebaseAuth();
      final fakeFirestore = FakeFirebaseFirestore();
      final custom = AuthService(auth: mockAuth, firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(custom),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(authServiceProvider);
      expect(service, same(custom));
    });
  });

  group('authStateProvider', () {
    test('未認証時にnullを返す', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final fakeFirestore = FakeFirebaseFirestore();
      final customService = AuthService(auth: mockAuth, firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(customService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final state = container.read(authStateProvider);
      expect(state.value, isNull);
    });

    test('ログイン済み時にUserを返す', () async {
      final user = MockUser(uid: 'test-uid', email: 'test@example.com');
      final mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final fakeFirestore = FakeFirebaseFirestore();
      final customService = AuthService(auth: mockAuth, firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(customService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final state = container.read(authStateProvider);
      expect(state.value, isA<User>());
      expect(state.value?.uid, equals('test-uid'));
    });
  });

  group('isAuthenticatedProvider', () {
    test('未認証時にfalseを返す', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final fakeFirestore = FakeFirebaseFirestore();
      final customService = AuthService(auth: mockAuth, firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(customService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isFalse);
    });

    test('認証済み時にtrueを返す', () async {
      final user = MockUser(uid: 'test-uid', email: 'test@example.com');
      final mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final fakeFirestore = FakeFirebaseFirestore();
      final customService = AuthService(auth: mockAuth, firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(customService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isTrue);
    });
  });

  group('currentUserUidProvider', () {
    test('未認証時に空文字を返す', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final fakeFirestore = FakeFirebaseFirestore();
      final customService = AuthService(auth: mockAuth, firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(customService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final uid = container.read(currentUserUidProvider);
      expect(uid, isEmpty);
    });

    test('認証済み時にUIDを返す', () async {
      final user = MockUser(uid: 'abc123', email: 'test@example.com');
      final mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final fakeFirestore = FakeFirebaseFirestore();
      final customService = AuthService(auth: mockAuth, firestore: fakeFirestore);
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(customService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      final uid = container.read(currentUserUidProvider);
      expect(uid, equals('abc123'));
    });
  });
}
