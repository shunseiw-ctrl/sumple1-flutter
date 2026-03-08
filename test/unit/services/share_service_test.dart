import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/share_service.dart';

void main() {
  group('ShareService.shareJobText', () {
    test('正常な引数_正しいフォーマットのテキストを生成する', () {
      final text =
          ShareService.shareJobText('job1', 'テスト案件', '15000', '東京都');
      expect(text, '【ALBAWORK】テスト案件\n場所: 東京都\n日給: 15000円\nhttps://alba-work.web.app/jobs/job1');
    });

    test('空文字の引数_空値を含むテキストを生成する', () {
      final text = ShareService.shareJobText('', '', '', '');
      expect(text, contains('【ALBAWORK】'));
      expect(text, contains('場所: \n'));
      expect(text, contains('日給: 円'));
      expect(text, contains('https://alba-work.web.app/jobs/'));
    });

    test('特殊文字を含む引数_エスケープせずそのまま出力する', () {
      final text = ShareService.shareJobText(
          'job-123', '内装工事【急募】', '20,000', '東京都渋谷区（駅近）');
      expect(text, contains('【ALBAWORK】内装工事【急募】'));
      expect(text, contains('場所: 東京都渋谷区（駅近）'));
      expect(text, contains('日給: 20,000円'));
      expect(text, contains('https://alba-work.web.app/jobs/job-123'));
    });

    test('URLにjobIdが正しく埋め込まれる', () {
      final text =
          ShareService.shareJobText('abc_456', 'タイトル', '10000', '大阪');
      expect(text, endsWith('https://alba-work.web.app/jobs/abc_456'));
    });
  });

  group('ShareService.shareReferralText', () {
    test('正常なコード_紹介コードを含むテキストを生成する', () {
      final text = ShareService.shareReferralText('ABC123');
      expect(text,
          'ALBAWORKで一緒に働こう！紹介コード: ABC123\nhttps://alba-work.web.app');
    });

    test('空文字のコード_コード部分が空のテキストを生成する', () {
      final text = ShareService.shareReferralText('');
      expect(text, contains('紹介コード: \n'));
      expect(text, contains('https://alba-work.web.app'));
    });

    test('長いコード_そのまま出力する', () {
      final longCode = 'A' * 100;
      final text = ShareService.shareReferralText(longCode);
      expect(text, contains('紹介コード: $longCode'));
    });
  });

  group('ShareService.shareAppText', () {
    test('引数なし_固定のアプリ紹介テキストを返す', () {
      final text = ShareService.shareAppText();
      expect(
          text, 'ALBAWORKで建設業の仕事を見つけよう！\nhttps://alba-work.web.app');
    });

    test('複数回呼び出し_同一のテキストを返す', () {
      final text1 = ShareService.shareAppText();
      final text2 = ShareService.shareAppText();
      expect(text1, equals(text2));
    });
  });
}
