import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization', () {
    late Map<String, dynamic> jaArb;
    late Map<String, dynamic> enArb;

    setUpAll(() {
      final jaFile = File('lib/l10n/app_ja.arb');
      final enFile = File('lib/l10n/app_en.arb');
      jaArb = jsonDecode(jaFile.readAsStringSync()) as Map<String, dynamic>;
      enArb = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
    });

    Set<String> _translationKeys(Map<String, dynamic> arb) {
      return arb.keys.where((k) => !k.startsWith('@') && k != '@@locale').toSet();
    }

    test('app_ja.arbとapp_en.arbのキー数が一致', () {
      final jaKeys = _translationKeys(jaArb);
      final enKeys = _translationKeys(enArb);

      final missingInEn = jaKeys.difference(enKeys);
      final extraInEn = enKeys.difference(jaKeys);

      expect(missingInEn, isEmpty,
          reason: 'app_en.arbに不足キー: $missingInEn');
      expect(extraInEn, isEmpty,
          reason: 'app_en.arbに余分なキー: $extraInEn');
    });

    test('全ARBキーが空でない（日本語）', () {
      final keys = _translationKeys(jaArb);
      for (final key in keys) {
        final value = jaArb[key];
        expect(value, isNotNull, reason: 'ja key "$key" is null');
        expect(value.toString().trim(), isNotEmpty,
            reason: 'ja key "$key" is empty');
      }
    });

    test('全ARBキーが空でない（英語）', () {
      final keys = _translationKeys(enArb);
      for (final key in keys) {
        final value = enArb[key];
        expect(value, isNotNull, reason: 'en key "$key" is null');
        expect(value.toString().trim(), isNotEmpty,
            reason: 'en key "$key" is empty');
      }
    });

    test('パラメータ付きキーが両言語で一致', () {
      final jaKeys = _translationKeys(jaArb);
      for (final key in jaKeys) {
        final jaVal = jaArb[key].toString();
        if (jaVal.contains('{') && jaVal.contains('}')) {
          // パラメータがある場合、英語にも同じパラメータがあるか
          expect(enArb.containsKey(key), isTrue,
              reason: 'Parameterized key "$key" missing in en');
          final enVal = enArb[key].toString();
          final jaParams = RegExp(r'\{(\w+)\}').allMatches(jaVal).map((m) => m.group(1)).toSet();
          final enParams = RegExp(r'\{(\w+)\}').allMatches(enVal).map((m) => m.group(1)).toSet();
          expect(enParams, equals(jaParams),
              reason: 'Parameter mismatch for key "$key": ja=$jaParams, en=$enParams');
        }
      }
    });
  });
}
