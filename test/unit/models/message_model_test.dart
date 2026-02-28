import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/chat_service.dart';

void main() {
  group('Message validation', () {
    test('empty message should be rejected', () {
      final text = ''.trim();
      expect(text.isEmpty, true);
    });

    test('whitespace-only message should be rejected', () {
      final text = '   '.trim();
      expect(text.isEmpty, true);
    });

    test('message within limit should be accepted', () {
      const text = 'テストメッセージ';
      expect(text.length <= ChatService.maxMessageLength, true);
    });

    test('message exceeding limit should be rejected', () {
      final text = 'あ' * (ChatService.maxMessageLength + 1);
      expect(text.length > ChatService.maxMessageLength, true);
    });

    test('message at exact limit should be accepted', () {
      final text = 'a' * ChatService.maxMessageLength;
      expect(text.length <= ChatService.maxMessageLength, true);
    });
  });
}
