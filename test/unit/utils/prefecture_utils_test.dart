import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/prefecture_utils.dart';

void main() {
  group('guessPrefecture', () {
    test('returns exact prefecture match', () {
      expect(guessPrefecture('千葉県千葉市'), '千葉県');
      expect(guessPrefecture('東京都渋谷区'), '東京都');
      expect(guessPrefecture('大阪府大阪市'), '大阪府');
    });

    test('returns partial match for short name', () {
      expect(guessPrefecture('東京渋谷'), '東京都');
      expect(guessPrefecture('千葉市内'), '千葉県');
      expect(guessPrefecture('神奈川横浜'), '神奈川県');
    });

    test('returns 未設定 for unknown location', () {
      expect(guessPrefecture('不明な場所'), '未設定');
      expect(guessPrefecture(''), '未設定');
    });

    test('prioritizes full prefecture name over partial', () {
      expect(guessPrefecture('京都府京都市'), '京都府');
      expect(guessPrefecture('大阪府堺市'), '大阪府');
    });
  });
}
