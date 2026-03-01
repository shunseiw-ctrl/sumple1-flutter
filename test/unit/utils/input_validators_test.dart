import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/input_validators.dart';

void main() {
  group('InputValidators.requiredField', () {
    test('returns error when null', () {
      expect(InputValidators.requiredField(null, '名前'), '名前は必須です');
    });

    test('returns error when empty', () {
      expect(InputValidators.requiredField('', '名前'), '名前は必須です');
    });

    test('returns error when whitespace only', () {
      expect(InputValidators.requiredField('   ', '名前'), '名前は必須です');
    });

    test('returns null when valid', () {
      expect(InputValidators.requiredField('テスト', '名前'), isNull);
    });
  });

  group('InputValidators.postalCode', () {
    test('returns null when empty', () {
      expect(InputValidators.postalCode(''), isNull);
    });

    test('returns null when null', () {
      expect(InputValidators.postalCode(null), isNull);
    });

    test('accepts format 123-4567', () {
      expect(InputValidators.postalCode('123-4567'), isNull);
    });

    test('accepts format 1234567', () {
      expect(InputValidators.postalCode('1234567'), isNull);
    });

    test('rejects invalid format', () {
      expect(InputValidators.postalCode('12-4567'), isNotNull);
    });

    test('rejects alphabetic characters', () {
      expect(InputValidators.postalCode('abc-defg'), isNotNull);
    });
  });

  group('InputValidators.experienceYears', () {
    test('returns null when empty', () {
      expect(InputValidators.experienceYears(''), isNull);
    });

    test('returns null when null', () {
      expect(InputValidators.experienceYears(null), isNull);
    });

    test('accepts valid number', () {
      expect(InputValidators.experienceYears('5'), isNull);
    });

    test('accepts zero', () {
      expect(InputValidators.experienceYears('0'), isNull);
    });

    test('rejects negative number', () {
      expect(InputValidators.experienceYears('-1'), isNotNull);
    });

    test('rejects non-numeric value', () {
      expect(InputValidators.experienceYears('abc'), isNotNull);
    });
  });

  group('InputValidators.maxLengthValidator', () {
    test('returns null when empty', () {
      expect(InputValidators.maxLengthValidator('', 100, 'タイトル'), isNull);
    });

    test('returns null when null', () {
      expect(InputValidators.maxLengthValidator(null, 100, 'タイトル'), isNull);
    });

    test('returns null when within limit', () {
      expect(InputValidators.maxLengthValidator('テスト', 100, 'タイトル'), isNull);
    });

    test('returns null at exact limit', () {
      final value = 'a' * 100;
      expect(InputValidators.maxLengthValidator(value, 100, 'タイトル'), isNull);
    });

    test('returns error when exceeding limit', () {
      final value = 'a' * 101;
      final result = InputValidators.maxLengthValidator(value, 100, 'タイトル');
      expect(result, contains('100'));
      expect(result, contains('タイトル'));
    });
  });
}
