import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/services/phone_auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class FakePhoneAuthCredential extends Fake implements PhoneAuthCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late PhoneAuthService service;

  setUpAll(() {
    registerFallbackValue(FakePhoneAuthCredential());
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    service = PhoneAuthService(auth: mockAuth);
  });

  group('PhoneAuthService', () {
    test('createCredential → PhoneAuthCredential返却', () {
      // PhoneAuthProvider.credentialは静的メソッドなので直接テスト
      // 実際のFirebase SDKではcredentialを生成する
      // ここではサービスメソッドが正しいパラメータを渡すことを確認
      final credential = service.createCredential(
        verificationId: 'test-verification-id',
        smsCode: '123456',
      );

      expect(credential, isA<PhoneAuthCredential>());
    });

    test('verifyPhoneNumber → Firebase呼出', () async {
      when(() => mockAuth.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            forceResendingToken: any(named: 'forceResendingToken'),
          )).thenAnswer((_) async {});

      await service.verifyPhoneNumber(
        phoneNumber: '+818012345678',
        onAutoVerified: (_) {},
        onCodeSent: (_, __) {},
        onError: (_) {},
      );

      verify(() => mockAuth.verifyPhoneNumber(
            phoneNumber: '+818012345678',
            verificationCompleted: any(named: 'verificationCompleted'),
            verificationFailed: any(named: 'verificationFailed'),
            codeSent: any(named: 'codeSent'),
            codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
            forceResendingToken: null,
          )).called(1);
    });

    test('signInWithCredential → FirebaseAuth委譲', () async {
      final mockCredential = FakePhoneAuthCredential();
      final mockResult = MockUserCredential();

      when(() => mockAuth.signInWithCredential(any()))
          .thenAnswer((_) async => mockResult);

      final result = await service.signInWithCredential(mockCredential);

      expect(result, mockResult);
      verify(() => mockAuth.signInWithCredential(mockCredential)).called(1);
    });
  });
}
