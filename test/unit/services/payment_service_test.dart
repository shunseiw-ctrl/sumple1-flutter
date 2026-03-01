import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/services/payment_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late PaymentService service;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    service = PaymentService(functions: mockFunctions);
  });

  group('PaymentService.createConnectAccount', () {
    test('calls createConnectAccount callable', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(() => mockFunctions.httpsCallable('createConnectAccount'))
          .thenReturn(mockCallable);
      when(() => mockResult.data).thenReturn({'accountId': 'acct_123', 'url': 'https://example.com'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final result = await service.createConnectAccount(email: 'test@test.com');
      expect(result['accountId'], 'acct_123');
      verify(() => mockFunctions.httpsCallable('createConnectAccount')).called(1);
    });
  });

  group('PaymentService.createAccountLink', () {
    test('returns URL string', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(() => mockFunctions.httpsCallable('createAccountLink'))
          .thenReturn(mockCallable);
      when(() => mockResult.data).thenReturn({'url': 'https://stripe.com/link'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final result = await service.createAccountLink();
      expect(result, 'https://stripe.com/link');
    });
  });

  group('PaymentService.getAccountStatus', () {
    test('returns status map', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(() => mockFunctions.httpsCallable('getAccountStatus'))
          .thenReturn(mockCallable);
      when(() => mockResult.data).thenReturn({'status': 'active'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final result = await service.getAccountStatus();
      expect(result['status'], 'active');
    });
  });

  group('PaymentService.createPaymentIntent', () {
    test('passes applicationId and amount', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(() => mockFunctions.httpsCallable('createPaymentIntent'))
          .thenReturn(mockCallable);
      when(() => mockResult.data).thenReturn({'paymentIntentId': 'pi_123'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final result = await service.createPaymentIntent(
        applicationId: 'app1',
        amount: 30000,
      );
      expect(result['paymentIntentId'], 'pi_123');
    });
  });

  group('PaymentService.getExpressDashboardLink', () {
    test('returns dashboard URL', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      when(() => mockFunctions.httpsCallable('getExpressDashboardLink'))
          .thenReturn(mockCallable);
      when(() => mockResult.data).thenReturn({'url': 'https://dashboard.stripe.com'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final result = await service.getExpressDashboardLink();
      expect(result, 'https://dashboard.stripe.com');
    });
  });

}
