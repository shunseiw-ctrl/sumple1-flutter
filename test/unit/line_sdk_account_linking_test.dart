import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'package:sumple1/core/services/line_auth_service.dart';
import 'package:sumple1/core/services/line_sdk_wrapper.dart';
import 'package:sumple1/core/services/account_linking_service.dart';

// モック定義
class MockHttpClient extends Mock implements http.Client {}

class MockLineSDKWrapper extends Mock implements LineSDKWrapper {}

class MockGoogleSignIn extends Mock {}

void main() {
  group('LineSDKWrapper', () {
    test('LoginResult がアクセストークンを保持する', () {
      const result = LineSDKLoginResult(
        accessToken: 'test_token',
        displayName: 'Test User',
        userId: 'U12345',
        pictureUrl: 'https://example.com/photo.jpg',
      );

      expect(result.accessToken, 'test_token');
      expect(result.displayName, 'Test User');
      expect(result.userId, 'U12345');
      expect(result.pictureUrl, 'https://example.com/photo.jpg');
    });

    test('LoginResult が空のフィールドを許容する', () {
      const result = LineSDKLoginResult(
        accessToken: 'token',
        displayName: '',
        userId: 'U00',
        pictureUrl: '',
      );

      expect(result.displayName, '');
      expect(result.pictureUrl, '');
    });
  });

  group('LineAuthService SDK フロー', () {
    late MockHttpClient mockHttpClient;
    late MockLineSDKWrapper mockLineSDK;
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late LineAuthService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockLineSDK = MockLineSDKWrapper();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'line:U12345', displayName: 'LINEユーザー'),
      );
      fakeFirestore = FakeFirebaseFirestore();
      service = LineAuthService.forTesting(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttpClient,
        lineSDK: mockLineSDK,
      );

      // URI 登録
      registerFallbackValue(Uri());
    });

    test('SDK login 成功 → verify-token → signInWithCustomToken', () async {
      // LINE SDK ログイン成功
      when(() => mockLineSDK.login()).thenAnswer((_) async => const LineSDKLoginResult(
            accessToken: 'access_token_123',
            displayName: 'テストユーザー',
            userId: 'U12345',
            pictureUrl: 'https://example.com/photo.jpg',
          ));

      // verify-token API 成功
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'customToken': 'custom_token_abc',
              'profile': {
                'displayName': 'Test User',
                'photoUrl': 'https://example.com/photo.jpg',
                'provider': 'line',
              },
            }),
            200,
          ));

      final result = await service.startLineLogin();

      // signInWithCustomToken が呼ばれるべき
      expect(result, isNotNull);
      expect(result!.user, isNotNull);
      verify(() => mockLineSDK.login()).called(1);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('SDK login キャンセル → null を返す', () async {
      when(() => mockLineSDK.login()).thenAnswer((_) async => null);

      final result = await service.startLineLogin();

      expect(result, isNull);
      verify(() => mockLineSDK.login()).called(1);
      verifyNever(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ));
    });

    test('verify-token API 失敗 → null を返す', () async {
      when(() => mockLineSDK.login()).thenAnswer((_) async => const LineSDKLoginResult(
            accessToken: 'access_token',
            displayName: 'ユーザー',
            userId: 'U99999',
            pictureUrl: '',
          ));

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'error': 'invalid_token'}),
            401,
          ));

      final result = await service.startLineLogin();

      expect(result, isNull);
    });

    test('SDK がない場合 → null を返す', () async {
      // lineSDK = null のサービス
      final serviceNoSDK = LineAuthService.forTesting(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttpClient,
        lineSDK: null,
      );

      final result = await serviceNoSDK.startLineLogin();
      expect(result, isNull);
    });
  });

  group('LineAuthService exchange フロー', () {
    late MockHttpClient mockHttpClient;
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late LineAuthService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'line:U12345', displayName: 'LINEユーザー'),
      );
      fakeFirestore = FakeFirebaseFirestore();
      service = LineAuthService.forTesting(
        auth: mockAuth,
        firestore: fakeFirestore,
        httpClient: mockHttpClient,
      );

      registerFallbackValue(Uri());
    });

    test('exchange 成功 → true を返す', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'customToken': 'custom_token_123',
              'profile': {
                'displayName': 'Test',
                'photoUrl': '',
                'provider': 'line',
              },
            }),
            200,
          ));

      final result = await service.handleMobileLineCallback(
        Uri.parse('https://alba-work.web.app/line-callback?code=exchange_code'),
      );

      expect(result, isTrue);
    });

    test('exchange コード欠落 → false を返す', () async {
      final result = await service.handleMobileLineCallback(
        Uri.parse('https://alba-work.web.app/line-callback'),
      );

      expect(result, isFalse);
    });

    test('exchange エラー応答 → false を返す', () async {
      final result = await service.handleMobileLineCallback(
        Uri.parse('https://alba-work.web.app/line-callback?error=access_denied'),
      );

      expect(result, isFalse);
    });
  });

  group('AccountLinkingService', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'test_user_123',
          displayName: 'テストユーザー',
          email: 'test@example.com',
        ),
      );
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('getLinkedProviders が providerData を返す', () {
      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      final providers = service.getLinkedProviders();
      // MockUser はデフォルトで空の providerData
      expect(providers, isA<List<String>>());
    });

    test('unlinkProvider がプロバイダー1つの場合例外を投げる', () {
      final service = AccountLinkingService(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      // providerData が空なので getLinkedProviders() は0〜1
      // 最低1つが必要なのでエラー
      expect(
        () => service.unlinkProvider('google.com'),
        throwsA(isA<Exception>()),
      );
    });

    test('LINE UID が line: で始まる場合 LINE プロバイダーを含む', () {
      final lineAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'line:U12345',
          displayName: 'LINEユーザー',
        ),
      );

      final service = AccountLinkingService(
        auth: lineAuth,
        firestore: fakeFirestore,
      );

      final providers = service.getLinkedProviders();
      expect(providers.contains('line'), isTrue);
    });
  });
}
