import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/analytics_service.dart';

/// AnalyticsService のインターフェーステスト
/// Firebase Analytics は実際のFirebase初期化が必要なため、
/// ここではクラスとメソッドの存在確認のみ行う。
/// 実際のイベント送信テストは統合テスト (firebase emulator) で実施。
void main() {
  group('AnalyticsService', () {
    test('can be imported', () {
      expect(true, isTrue);
    });

    // --- 既存メソッド ---

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

    // --- Phase 8A-2 新規メソッド ---

    test('logScreenView method exists', () {
      expect(AnalyticsService.logScreenView, isA<Function>());
    });

    test('logChatMessage method exists', () {
      expect(AnalyticsService.logChatMessage, isA<Function>());
    });

    test('logFavoriteRemove method exists', () {
      expect(AnalyticsService.logFavoriteRemove, isA<Function>());
    });

    test('logContactSubmit method exists', () {
      expect(AnalyticsService.logContactSubmit, isA<Function>());
    });

    test('logEarningCreate method exists', () {
      expect(AnalyticsService.logEarningCreate, isA<Function>());
    });

    test('logProfileEdit method exists', () {
      expect(AnalyticsService.logProfileEdit, isA<Function>());
    });

    test('logCheckIn method exists', () {
      expect(AnalyticsService.logCheckIn, isA<Function>());
    });

    test('logCheckOut method exists', () {
      expect(AnalyticsService.logCheckOut, isA<Function>());
    });

    test('logStripeOnboarding method exists', () {
      expect(AnalyticsService.logStripeOnboarding, isA<Function>());
    });

    test('logNotificationOpen method exists', () {
      expect(AnalyticsService.logNotificationOpen, isA<Function>());
    });

    test('setUserId method exists', () {
      expect(AnalyticsService.setUserId, isA<Function>());
    });

    test('setUserPrefecture method exists', () {
      expect(AnalyticsService.setUserPrefecture, isA<Function>());
    });
  });
}
