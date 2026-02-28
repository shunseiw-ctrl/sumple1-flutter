import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/chat_service.dart';

void main() {
  group('ChatService', () {
    group('maxMessageLength', () {
      test('should be 5000', () {
        expect(ChatService.maxMessageLength, 5000);
      });
    });

    group('SendMessageResult', () {
      test('success factory creates successful result', () {
        final result = SendMessageResult.success();
        expect(result.success, true);
        expect(result.errorMessage, isNull);
      });

      test('error factory creates failed result with message', () {
        final result = SendMessageResult.error('テストエラー');
        expect(result.success, false);
        expect(result.errorMessage, 'テストエラー');
      });
    });

    group('ChatRoomInitResult', () {
      test('success factory creates successful result with all fields', () {
        final result = ChatRoomInitResult.success(
          applicantUid: 'applicant-1',
          adminUid: 'admin-1',
          jobId: 'job-1',
          titleSnapshot: 'テスト案件',
          isApplicant: true,
          isAdmin: false,
        );
        expect(result.success, true);
        expect(result.applicantUid, 'applicant-1');
        expect(result.adminUid, 'admin-1');
        expect(result.jobId, 'job-1');
        expect(result.titleSnapshot, 'テスト案件');
        expect(result.isApplicant, true);
        expect(result.isAdmin, false);
        expect(result.errorMessage, isNull);
      });

      test('error factory creates failed result', () {
        final result = ChatRoomInitResult.error('エラーメッセージ');
        expect(result.success, false);
        expect(result.errorMessage, 'エラーメッセージ');
        expect(result.isApplicant, false);
        expect(result.isAdmin, false);
      });
    });
  });
}
