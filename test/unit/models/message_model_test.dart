import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/message_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('MessageModel', () {
    group('fromMap', () {
      test('完全なデータで正しく生成される', () {
        final data = TestFixtures.messageData();
        final model = MessageModel.fromMap('msg-001', data);

        expect(model.id, 'msg-001');
        expect(model.senderUid, 'worker-001');
        expect(model.text, 'テストメッセージです');
        expect(model.createdAt, isNotNull);
      });

      test('必須フィールドが欠落した場合は空文字列', () {
        final model = MessageModel.fromMap('msg-002', {});

        expect(model.senderUid, '');
        expect(model.text, '');
        expect(model.createdAt, isNull);
      });

      test('nullフィールドが安全に処理される', () {
        final model = MessageModel.fromMap('msg-003', {
          'senderUid': null,
          'text': null,
          'createdAt': null,
        });

        expect(model.senderUid, '');
        expect(model.text, '');
        expect(model.createdAt, isNull);
      });
    });

    group('isSender', () {
      test('送信者UIDで真', () {
        final model = MessageModel.fromMap('msg-001', TestFixtures.messageData());
        expect(model.isSender('worker-001'), isTrue);
      });

      test('別のUIDで偽', () {
        final model = MessageModel.fromMap('msg-001', TestFixtures.messageData());
        expect(model.isSender('admin-001'), isFalse);
      });
    });

    group('isNotEmpty', () {
      test('テキストありでtrue', () {
        final model = MessageModel.fromMap('msg-001', TestFixtures.messageData(text: 'hello'));
        expect(model.isNotEmpty, isTrue);
      });

      test('空文字列でfalse', () {
        final model = MessageModel.fromMap('msg-002', TestFixtures.messageData(text: ''));
        expect(model.isNotEmpty, isFalse);
      });

      test('空白のみでfalse', () {
        final model = MessageModel.fromMap('msg-003', TestFixtures.messageData(text: '   '));
        expect(model.isNotEmpty, isFalse);
      });
    });

    test('copyWithで指定フィールドのみ変更される', () {
      final original = MessageModel.fromMap('msg-001', TestFixtures.messageData());
      final copied = original.copyWith(text: '新しいテキスト');

      expect(copied.text, '新しいテキスト');
      expect(copied.id, original.id);
      expect(copied.senderUid, original.senderUid);
    });
  });
}
