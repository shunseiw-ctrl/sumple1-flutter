import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/share_service.dart';

void main() {
  group('ShareService', () {
    test('shareJobText generates correct format', () {
      final text = ShareService.shareJobText('job1', 'テスト案件', '15000', '東京都');
      expect(text, contains('【ALBAWORK】テスト案件'));
      expect(text, contains('場所: 東京都'));
      expect(text, contains('日給: 15000円'));
      expect(text, contains('https://albawork.app/jobs/job1'));
    });

    test('shareReferralText generates correct format', () {
      final text = ShareService.shareReferralText('ABC123');
      expect(text, contains('紹介コード: ABC123'));
      expect(text, contains('https://albawork.app'));
    });

    test('shareAppText generates correct format', () {
      final text = ShareService.shareAppText();
      expect(text, contains('ALBAWORK'));
      expect(text, contains('https://albawork.app'));
    });

    test('shareJobText handles empty values', () {
      final text = ShareService.shareJobText('', '', '', '');
      expect(text, contains('【ALBAWORK】'));
      expect(text, contains('https://albawork.app/jobs/'));
    });
  });
}
