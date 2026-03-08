import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import 'package:sumple1/core/services/account_linking_service.dart';

// ===== モック定義 =====

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

// fallbackValue 用のフェイク
class FakeAuthCredential extends Fake implements AuthCredential {}

/// UserInfo を作成するヘルパー
UserInfo _createUserInfo(String providerId) {
  return UserInfo.fromPigeon(PigeonUserInfo(
    uid: 'test_uid',
    isAnonymous: false,
    isEmailVerified: true,
    providerId: providerId,
  ));
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  // ================================================================
  // linkGoogle テスト
  // ================================================================
  group('AccountLinkingService - linkGoogle', () {
    late MockGoogleSignIn mockGoogleSignIn;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseFunctions mockFunctions;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockUser = MockUser(
        uid: 'test_user_google',
        displayName: 'テストユーザー',
        email: 'test@example.com',
      );
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );
      fakeFirestore = FakeFirebaseFirestore();
      mockFunctions = MockFirebaseFunctions();
    });

    test('linkGoogle_成功_LinkResult.successを返す', () async {
      // Google SignIn モック設定
      final mockAccount = MockGoogleSignInAccount();
      final mockAuthentication = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuthentication);
      when(() => mockAuthentication.accessToken)
          .thenReturn('mock-access-token');
      when(() => mockAuthentication.idToken).thenReturn('mock-id-token');

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
        functions: mockFunctions,
      );

      final result = await service.linkGoogle();

      expect(result.success, isTrue);
      expect(result.needsMerge, isFalse);
      verify(() => mockGoogleSignIn.signIn()).called(1);
    });

    test('linkGoogle_キャンセル_LinkResult.cancelledを返す', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
        functions: mockFunctions,
      );

      final result = await service.linkGoogle();

      expect(result.success, isFalse);
      expect(result.needsMerge, isFalse);
      expect(result.credential, isNull);
      expect(result.conflictingEmail, isNull);
    });

    test('linkGoogle_credential-already-in-use_LinkResult.mergeを返す', () async {
      // Google SignIn 設定（credential取得まで成功）
      final mockAccount = MockGoogleSignInAccount();
      final mockAuthentication = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuthentication);
      when(() => mockAuthentication.accessToken)
          .thenReturn('mock-access-token');
      when(() => mockAuthentication.idToken).thenReturn('mock-id-token');

      // signInSilently でemail取得
      when(() => mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.email).thenReturn('existing@example.com');

      // linkWithCredential で credential-already-in-use を投げる
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: 'mock-access-token',
        idToken: 'mock-id-token',
      );
      whenCalling(Invocation.method(#linkWithCredential, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(
            code: 'credential-already-in-use',
            email: 'existing@example.com',
            credential: googleCredential,
          ));

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
        functions: mockFunctions,
      );

      final result = await service.linkGoogle();

      expect(result.success, isFalse);
      expect(result.needsMerge, isTrue);
      expect(result.conflictingEmail, 'existing@example.com');
      expect(result.credential, isNotNull);
    });

    test('linkGoogle_認証例外_rethrowする', () async {
      // Google SignIn で認証取得に失敗するケース
      final mockAccount = MockGoogleSignInAccount();

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenThrow(Exception('authentication failed'));

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
        functions: mockFunctions,
      );

      expect(
        () => service.linkGoogle(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ================================================================
  // linkEmail テスト
  // ================================================================
  group('AccountLinkingService - linkEmail', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseFunctions mockFunctions;

    setUp(() {
      mockUser = MockUser(
        uid: 'test_user_email',
        displayName: 'テストユーザー',
        email: 'test@example.com',
      );
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );
      fakeFirestore = FakeFirebaseFirestore();
      mockFunctions = MockFirebaseFunctions();
    });

    test('linkEmail_成功_LinkResult.successを返す', () async {
      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      // MockFirebaseAuth の linkWithCredential はデフォルトで成功する
      final result = await service.linkEmail(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(result.success, isTrue);
      expect(result.needsMerge, isFalse);
    });

    test('linkEmail_credential-already-in-use_LinkResult.mergeを返す', () async {
      // linkWithCredential で credential-already-in-use を投げる
      final emailCredential = EmailAuthProvider.credential(
        email: 'existing@example.com',
        password: 'password123',
      );
      whenCalling(Invocation.method(#linkWithCredential, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(
            code: 'credential-already-in-use',
            email: 'existing@example.com',
            credential: emailCredential,
          ));

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final result = await service.linkEmail(
        email: 'existing@example.com',
        password: 'password123',
      );

      expect(result.success, isFalse);
      expect(result.needsMerge, isTrue);
      expect(result.conflictingEmail, 'existing@example.com');
      expect(result.credential, isNotNull);
    });
  });

  // ================================================================
  // linkPhone テスト
  // ================================================================
  group('AccountLinkingService - linkPhone', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseFunctions mockFunctions;

    setUp(() {
      mockUser = MockUser(
        uid: 'test_user_phone',
        displayName: 'テストユーザー',
      );
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );
      fakeFirestore = FakeFirebaseFirestore();
      mockFunctions = MockFirebaseFunctions();
    });

    test('linkPhone_成功_LinkResult.successを返す', () async {
      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final credential = PhoneAuthProvider.credential(
        verificationId: 'test_verification_id',
        smsCode: '123456',
      );

      // MockFirebaseAuth の linkWithCredential はデフォルトで成功する
      final result = await service.linkPhone(credential: credential);

      expect(result.success, isTrue);
      expect(result.needsMerge, isFalse);
    });

    test('linkPhone_その他の例外_rethrowする', () async {
      // linkWithCredential で credential-already-in-use を投げる
      // Phone にはemailがないのでマージ不可→rethrow
      whenCalling(Invocation.method(#linkWithCredential, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(
            code: 'credential-already-in-use',
          ));

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final credential = PhoneAuthProvider.credential(
        verificationId: 'test_verification_id',
        smsCode: '123456',
      );

      expect(
        () => service.linkPhone(credential: credential),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ================================================================
  // mergeAndLink テスト
  // ================================================================
  group('AccountLinkingService - mergeAndLink', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseFunctions mockFunctions;

    setUp(() {
      mockUser = MockUser(
        uid: 'test_user_merge',
        displayName: 'テストユーザー',
      );
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );
      fakeFirestore = FakeFirebaseFirestore();
      mockFunctions = MockFirebaseFunctions();
    });

    test('mergeAndLink_CF呼出後にlinkWithCredential再試行', () async {
      // Cloud Functions モック
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(() => mockFunctions.httpsCallable('mergeAccounts'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: 'merge-access-token',
        idToken: 'merge-id-token',
      );

      // mergeAndLink が例外なく完了すること
      await service.mergeAndLink(credential, 'conflict@example.com');

      // CF mergeAccounts が呼ばれたことを確認
      verify(() => mockFunctions.httpsCallable('mergeAccounts')).called(1);
      verify(() => mockCallable.call(any())).called(1);
    });
  });

  // ================================================================
  // getLinkedProviders テスト
  // ================================================================
  group('AccountLinkingService - getLinkedProviders', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseFunctions mockFunctions;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockFunctions = MockFirebaseFunctions();
    });

    test('getLinkedProviders_providerDataからプロバイダーIDを返す', () {
      final mockUser = MockUser(
        uid: 'test_user_providers',
        displayName: 'テストユーザー',
        providerData: [
          _createUserInfo('google.com'),
          _createUserInfo('password'),
        ],
      );
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final providers = service.getLinkedProviders();
      expect(providers, contains('google.com'));
      expect(providers, contains('password'));
      expect(providers.length, 2);
    });

    test('getLinkedProviders_LINEユーザー_lineプロバイダーを含む', () {
      final mockUser = MockUser(
        uid: 'line:U12345',
        displayName: 'LINEユーザー',
      );
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final providers = service.getLinkedProviders();
      expect(providers, contains('line'));
    });

    test('getLinkedProviders_未ログイン_空リストを返す', () {
      final mockAuth = MockFirebaseAuth(signedIn: false);

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final providers = service.getLinkedProviders();
      expect(providers, isEmpty);
    });
  });

  // ================================================================
  // unlinkProvider テスト
  // ================================================================
  group('AccountLinkingService - unlinkProvider', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseFunctions mockFunctions;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockFunctions = MockFirebaseFunctions();
    });

    test('unlinkProvider_成功_プロバイダーをunlinkする', () async {
      // 2つ以上のプロバイダーを持つユーザー
      final mockUser = MockUser(
        uid: 'test_user_unlink',
        displayName: 'テストユーザー',
        providerData: [
          _createUserInfo('google.com'),
          _createUserInfo('password'),
        ],
      );
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      // unlinkProvider が例外なく完了すること
      await service.unlinkProvider('google.com');

      // unlink後は password のみ残る
      final providers = service.getLinkedProviders();
      expect(providers, contains('password'));
      expect(providers, isNot(contains('google.com')));
    });

    test('unlinkProvider_最後のプロバイダー_例外を投げる', () {
      // プロバイダーが1つだけのユーザー
      final mockUser = MockUser(
        uid: 'test_user_last',
        displayName: 'テストユーザー',
        providerData: [
          _createUserInfo('google.com'),
        ],
      );
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: mockUser,
      );

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      expect(
        () => service.unlinkProvider('google.com'),
        throwsA(isA<Exception>()),
      );
    });

    test('unlinkProvider_未ログイン_例外を投げる', () {
      final mockAuth = MockFirebaseAuth(signedIn: false);

      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      expect(
        () => service.unlinkProvider('google.com'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
