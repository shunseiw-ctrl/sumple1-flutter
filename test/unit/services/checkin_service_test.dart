import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/checkin_service.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('CheckinService', () {
    group('parseQrData', () {
      test('有効なQRデータを正しくパースする', () {
        final result = CheckinService.parseQrData(
          TestFixtures.validQrData(jobId: 'job-123', shiftCode: 'abc-def'),
        );

        expect(result, isNotNull);
        expect(result!.jobId, 'job-123');
        expect(result.shiftCode, 'abc-def');
      });

      test('無効なスキームでnull', () {
        final result = CheckinService.parseQrData('https://checkin/job-001/shift-001');
        expect(result, isNull);
      });

      test('不正なホストでnull', () {
        final result = CheckinService.parseQrData('albawork://checkout/job-001/shift-001');
        expect(result, isNull);
      });

      test('パスセグメント不足でnull', () {
        final result = CheckinService.parseQrData('albawork://checkin/job-001');
        expect(result, isNull);
      });

      test('パスセグメント過多でnull', () {
        final result = CheckinService.parseQrData('albawork://checkin/job-001/shift-001/extra');
        expect(result, isNull);
      });

      test('空文字列でnull', () {
        final result = CheckinService.parseQrData('');
        expect(result, isNull);
      });

      test('完全に無効なURIでnull', () {
        final result = CheckinService.parseQrData('not a uri at all : /// ///');
        expect(result, isNull);
      });

      test('スキームなしのURLでnull', () {
        final result = CheckinService.parseQrData('checkin/job-001/shift-001');
        expect(result, isNull);
      });
    });

    group('CheckinResult', () {
      test('成功結果のプロパティ', () {
        final result = CheckinResult(
          success: true,
          message: '出勤しました',
          distance: 50.0,
        );

        expect(result.success, isTrue);
        expect(result.message, '出勤しました');
        expect(result.distance, 50.0);
      });

      test('失敗結果のプロパティ', () {
        final result = CheckinResult(
          success: false,
          message: '無効なQRコードです',
        );

        expect(result.success, isFalse);
        expect(result.message, '無効なQRコードです');
        expect(result.distance, isNull);
      });
    });

    test('maxDistanceMetersは100m', () {
      expect(CheckinService.maxDistanceMeters, 100.0);
    });
  });
}
