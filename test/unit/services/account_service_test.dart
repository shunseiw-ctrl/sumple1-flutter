import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/services/account_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late AccountService service;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    service = AccountService(functions: mockFunctions);
  });

  group('AccountService.deleteAccount', () {
    test('calls deleteUserData callable', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(() => mockFunctions.httpsCallable('deleteUserData'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call()).thenAnswer((_) async => mockResult);

      await service.deleteAccount();

      verify(() => mockFunctions.httpsCallable('deleteUserData')).called(1);
      verify(() => mockCallable.call()).called(1);
    });

    test('throws when CF fails', () async {
      final mockCallable = MockHttpsCallable();

      when(() => mockFunctions.httpsCallable('deleteUserData'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call()).thenThrow(
        FirebaseFunctionsException('internal', message: 'Server error'),
      );

      expect(() => service.deleteAccount(), throwsA(isA<FirebaseFunctionsException>()));
    });
  });

  group('AccountService.exportUserData', () {
    test('calls exportUserData callable and returns data', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();
      final testData = {
        'uid': 'test-uid',
        'profile': {'displayName': 'Test User'},
        'applications': [],
      };

      when(() => mockFunctions.httpsCallable('exportUserData'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call()).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn(testData);

      final result = await service.exportUserData();

      expect(result['uid'], equals('test-uid'));
      expect(result['profile'], isA<Map>());
      verify(() => mockFunctions.httpsCallable('exportUserData')).called(1);
    });

    test('returns empty profile as null', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();
      final testData = {
        'uid': 'test-uid',
        'profile': null,
        'applications': [],
      };

      when(() => mockFunctions.httpsCallable('exportUserData'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call()).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn(testData);

      final result = await service.exportUserData();

      expect(result['profile'], isNull);
    });

    test('throws when CF fails', () async {
      final mockCallable = MockHttpsCallable();

      when(() => mockFunctions.httpsCallable('exportUserData'))
          .thenReturn(mockCallable);
      when(() => mockCallable.call()).thenThrow(
        FirebaseFunctionsException('internal', message: 'Server error'),
      );

      expect(() => service.exportUserData(), throwsA(isA<FirebaseFunctionsException>()));
    });
  });
}

/// FirebaseFunctionsException はパッケージ内部クラスのため簡易再現
class FirebaseFunctionsException implements Exception {
  final String code;
  final String? message;
  FirebaseFunctionsException(this.code, {this.message});
}
