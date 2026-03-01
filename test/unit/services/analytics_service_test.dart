import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/analytics_service.dart';

/// AnalyticsService のインターフェーステスト
/// Firebase Analytics は実際のFirebase初期化が必要なため、
/// ここではクラスとメソッドの存在確認のみ行う。
/// 実際のイベント送信テストは統合テスト (firebase emulator) で実施。
void main() {
  group('AnalyticsService', () {
    test('can be imported', () {
      // AnalyticsService がインポートできること自体を確認
      // (Firebase未初期化でもインポートは成功する)
      expect(true, isTrue);
    });

    test('logJobView method exists', () {
      expect(AnalyticsService.logJobView, isA<Function>());
    });

    test('logJobApply method exists', () {
      expect(AnalyticsService.logJobApply, isA<Function>());
    });

    test('logJobPost method exists', () {
      expect(AnalyticsService.logJobPost, isA<Function>());
    });

    test('logChatStart method exists', () {
      expect(AnalyticsService.logChatStart, isA<Function>());
    });

    test('logSearch method exists', () {
      expect(AnalyticsService.logSearch, isA<Function>());
    });

    test('logFavoriteAdd method exists', () {
      expect(AnalyticsService.logFavoriteAdd, isA<Function>());
    });

    test('logSignUp method exists', () {
      expect(AnalyticsService.logSignUp, isA<Function>());
    });

    test('logLogin method exists', () {
      expect(AnalyticsService.logLogin, isA<Function>());
    });

    test('setUserRole method exists', () {
      expect(AnalyticsService.setUserRole, isA<Function>());
    });
  });
}
