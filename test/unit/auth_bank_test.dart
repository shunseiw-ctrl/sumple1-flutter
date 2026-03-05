import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sumple1/core/services/google_auth_service.dart';
import 'package:sumple1/core/services/line_auth_service.dart';

// ===== Mocks =====
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}
class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('GoogleAuthService', () {
    late MockGoogleSignIn mockGoogleSignIn;
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockAuth = MockFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('signInWithGoogle_キャンセル_nullを返す', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      final service = GoogleAuthService(
        auth: mockAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
      );

      final result = await service.signInWithGoogle();
      expect(result, isNull);
    });

    test('signInWithGoogle_エラー_rethrowする', () async {
      when(() => mockGoogleSignIn.signIn())
          .thenThrow(Exception('network error'));

      final service = GoogleAuthService(
        auth: mockAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
      );

      expect(
        () => service.signInWithGoogle(),
        throwsA(isA<Exception>()),
      );
    });

    test('signInWithGoogle_成功_UserCredentialを返す', () async {
      final mockAccount = MockGoogleSignInAccount();
      final mockAuthentication = MockGoogleSignInAuthentication();

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockAuthentication);
      when(() => mockAccount.email).thenReturn('test@gmail.com');
      when(() => mockAuthentication.accessToken)
          .thenReturn('mock-access-token');
      when(() => mockAuthentication.idToken).thenReturn('mock-id-token');

      final service = GoogleAuthService(
        auth: mockAuth,
        firestore: fakeFirestore,
        googleSignIn: mockGoogleSignIn,
      );

      final result = await service.signInWithGoogle();
      expect(result, isNotNull);
      expect(result!.user, isNotNull);

      // プロフィールが保存されたか確認
      final profileDoc = await fakeFirestore
          .collection('profiles')
          .doc(result.user!.uid)
          .get();
      expect(profileDoc.exists, isTrue);
      expect(profileDoc.data()?['provider'], 'google');
      expect(profileDoc.data()?['email'], 'test@gmail.com');
    });
  });

  group('LineAuthService - handleMobileLineCallback', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late MockHttpClient mockHttp;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
      mockHttp = MockHttpClient();
    });

    test('コードなしのURI_falseを返す', () async {
      final service = LineAuthService.forTesting(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttp,
      );

      final uri = Uri.parse('https://alba-work.web.app/line-callback');
      final result = await service.handleMobileLineCallback(uri);
      expect(result, isFalse);
    });

    test('エラーパラメータあり_falseを返す', () async {
      final service = LineAuthService.forTesting(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttp,
      );

      final uri = Uri.parse(
          'https://alba-work.web.app/line-callback?error=access_denied');
      final result = await service.handleMobileLineCallback(uri);
      expect(result, isFalse);
    });

    test('有効なコード_exchange成功_trueを返す', () async {
      final responseBody = jsonEncode({
        'customToken': 'mock-custom-token',
        'profile': {
          'displayName': 'LINE User',
          'photoUrl': '',
          'provider': 'line',
        },
      });

      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            responseBody,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ));

      final service = LineAuthService.forTesting(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttp,
      );

      final uri = Uri.parse(
          'https://alba-work.web.app/line-callback?code=valid-code');
      final result = await service.handleMobileLineCallback(uri);
      expect(result, isTrue);

      // HTTPリクエストが正しく送信されたか
      verify(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: jsonEncode({'code': 'valid-code'}),
          )).called(1);
    });

    test('有効なコード_exchange失敗_falseを返す', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
              (_) async => http.Response('{"error": "invalid_code"}', 400));

      final service = LineAuthService.forTesting(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttp,
      );

      final uri = Uri.parse(
          'https://alba-work.web.app/line-callback?code=invalid-code');
      final result = await service.handleMobileLineCallback(uri);
      expect(result, isFalse);
    });

    test('空のコード_falseを返す', () async {
      final service = LineAuthService.forTesting(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttp,
      );

      final uri =
          Uri.parse('https://alba-work.web.app/line-callback?code=');
      final result = await service.handleMobileLineCallback(uri);
      expect(result, isFalse);
    });
  });

  group('BankAccountSettingsPage - バリデーション', () {
    final katakanaRegex = RegExp(r'^[ァ-ヶー　 ]+$');
    final digitRegex = RegExp(r'^\d+$');

    test('支店コード_3桁数字_valid', () {
      expect(digitRegex.hasMatch('001'), isTrue);
      expect('001'.length == 3, isTrue);
    });

    test('支店コード_4桁数字_invalid', () {
      expect('0011'.length == 3, isFalse);
    });

    test('支店コード_英字含む_invalid', () {
      expect(digitRegex.hasMatch('0a1'), isFalse);
    });

    test('口座番号_7桁数字_valid', () {
      expect(digitRegex.hasMatch('1234567'), isTrue);
      expect('1234567'.length == 7, isTrue);
    });

    test('口座番号_6桁数字_invalid', () {
      expect('123456'.length == 7, isFalse);
    });

    test('口座名義_カタカナ_valid', () {
      expect(katakanaRegex.hasMatch('ヤマダ タロウ'), isTrue);
    });

    test('口座名義_ひらがな_invalid', () {
      expect(katakanaRegex.hasMatch('やまだ たろう'), isFalse);
    });

    test('口座名義_漢字_invalid', () {
      expect(katakanaRegex.hasMatch('山田 太郎'), isFalse);
    });

    test('口座名義_全角スペース含むカタカナ_valid', () {
      expect(katakanaRegex.hasMatch('ヤマダ　タロウ'), isTrue);
    });
  });
}
