import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/app_result.dart';

void main() {
  group('AppResult', () {
    test('AppSuccess生成と値アクセス', () {
      const result = AppSuccess<String>('hello');
      expect(result.data, 'hello');
      expect(result.value, 'hello');
      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.errorMessage, null);
    });

    test('AppError生成とメッセージアクセス', () {
      const result = AppError<String>('エラーです', originalError: 'raw_error');
      expect(result.data, null);
      expect(result.message, 'エラーです');
      expect(result.originalError, 'raw_error');
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.errorMessage, 'エラーです');
    });

    test('whenパターンマッチ成功時', () {
      const AppResult<int> result = AppSuccess(42);
      final output = result.when(
        success: (data) => 'ok: $data',
        error: (msg, _) => 'err: $msg',
      );
      expect(output, 'ok: 42');
    });

    test('whenパターンマッチエラー時', () {
      const AppResult<int> result = AppError('失敗');
      final output = result.when(
        success: (data) => 'ok: $data',
        error: (msg, _) => 'err: $msg',
      );
      expect(output, 'err: 失敗');
    });

    test('isSuccess/isErrorフラグ', () {
      const AppResult<String> success = AppSuccess('data');
      const AppResult<String> error = AppError('error');

      expect(success.isSuccess, true);
      expect(success.isError, false);
      expect(error.isSuccess, false);
      expect(error.isError, true);
    });

    test('originalErrorが省略可能', () {
      const result = AppError<String>('msg');
      expect(result.originalError, null);
    });
  });
}
