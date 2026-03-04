import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils.formatYen', () {
    test('0を¥0にフォーマット', () {
      expect(CurrencyUtils.formatYen(0), '¥0');
    });

    test('正の整数を¥プレフィックス+3桁区切りでフォーマット', () {
      expect(CurrencyUtils.formatYen(15000), '¥15,000');
    });

    test('負の整数を-¥プレフィックス+3桁区切りでフォーマット', () {
      expect(CurrencyUtils.formatYen(-5000), '-¥5,000');
    });

    test('大きな数値を正しくフォーマット', () {
      expect(CurrencyUtils.formatYen(1000000), '¥1,000,000');
    });

    test('3桁未満の数値はカンマなし', () {
      expect(CurrencyUtils.formatYen(999), '¥999');
    });

    test('ちょうど3桁の数値はカンマなし', () {
      expect(CurrencyUtils.formatYen(100), '¥100');
    });

    test('1桁の数値はそのまま', () {
      expect(CurrencyUtils.formatYen(1), '¥1');
    });

    test('大きな負の数値を正しくフォーマット', () {
      expect(CurrencyUtils.formatYen(-1234567), '-¥1,234,567');
    });
  });

  group('CurrencyUtils.formatNumber', () {
    test('0をそのままフォーマット', () {
      expect(CurrencyUtils.formatNumber(0), '0');
    });

    test('正の整数を3桁区切りでフォーマット（¥なし）', () {
      expect(CurrencyUtils.formatNumber(15000), '15,000');
    });

    test('負の整数を3桁区切りでフォーマット', () {
      expect(CurrencyUtils.formatNumber(-5000), '-5,000');
    });

    test('大きな数値を正しくフォーマット', () {
      expect(CurrencyUtils.formatNumber(1000000), '1,000,000');
    });
  });
}
