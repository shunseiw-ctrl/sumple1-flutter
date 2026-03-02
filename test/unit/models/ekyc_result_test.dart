import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/ekyc_result.dart';

void main() {
  group('EkycResult', () {
    test('EkycSuccess creates correctly with verificationId', () {
      const result = EkycSuccess(verificationId: 'verify-123');
      expect(result.verificationId, 'verify-123');
      expect(result, isA<EkycResult>());
      expect(result, isA<EkycSuccess>());

      // equality
      const result2 = EkycSuccess(verificationId: 'verify-123');
      expect(result, equals(result2));
      expect(result.hashCode, result2.hashCode);

      // inequality
      const result3 = EkycSuccess(verificationId: 'verify-456');
      expect(result, isNot(equals(result3)));
    });

    test('EkycPending and EkycError create correctly', () {
      const pending = EkycPending(message: '審査中です');
      expect(pending.message, '審査中です');
      expect(pending, isA<EkycResult>());

      // EkycPending equality
      const pending2 = EkycPending(message: '審査中です');
      expect(pending, equals(pending2));
      expect(pending.hashCode, pending2.hashCode);

      const error = EkycError(message: 'エラー発生', error: 'some error');
      expect(error.message, 'エラー発生');
      expect(error.error, 'some error');
      expect(error, isA<EkycResult>());

      // EkycError equality (based on message only)
      const error2 = EkycError(message: 'エラー発生', error: 'different error');
      expect(error, equals(error2));
      expect(error.hashCode, error2.hashCode);

      // EkycError without error field
      const errorNoDetail = EkycError(message: 'エラー');
      expect(errorNoDetail.error, isNull);
    });

    test('EkycUnavailable creates correctly, equality works', () {
      const unavailable = EkycUnavailable();
      expect(unavailable, isA<EkycResult>());

      const unavailable2 = EkycUnavailable();
      expect(unavailable, equals(unavailable2));
      expect(unavailable.hashCode, unavailable2.hashCode);

      // Not equal to other types
      const pending = EkycPending(message: 'test');
      expect(unavailable, isNot(equals(pending)));
    });
  });

  group('EkycStatus', () {
    test('has all expected values', () {
      expect(EkycStatus.values, contains(EkycStatus.notStarted));
      expect(EkycStatus.values, contains(EkycStatus.pending));
      expect(EkycStatus.values, contains(EkycStatus.approved));
      expect(EkycStatus.values, contains(EkycStatus.rejected));
      expect(EkycStatus.values, contains(EkycStatus.unavailable));
      expect(EkycStatus.values.length, 5);
    });
  });
}
