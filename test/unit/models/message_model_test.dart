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

    group('fromMap - 画像メッセージ', () {
      test('imageUrl・messageType正常パース', () {
        final model = MessageModel.fromMap('msg-img', {
          'senderUid': 'worker-001',
          'text': '',
          'imageUrl': 'https://example.com/image.jpg',
          'messageType': 'image',
          'createdAt': DateTime(2025, 1, 1),
        });

        expect(model.imageUrl, 'https://example.com/image.jpg');
        expect(model.messageType, 'image');
      });

      test('imageUrl未設定→null、messageType未設定→text', () {
        final model = MessageModel.fromMap('msg-old', {
          'senderUid': 'worker-001',
          'text': 'テスト',
          'createdAt': DateTime(2025, 1, 1),
        });

        expect(model.imageUrl, isNull);
        expect(model.messageType, 'text');
      });
    });

    group('isImage', () {
      test('messageType==image→true', () {
        final model = MessageModel(
          id: 'msg-001',
          senderUid: 'worker-001',
          text: '',
          imageUrl: 'https://example.com/image.jpg',
          messageType: 'image',
        );
        expect(model.isImage, isTrue);
      });

      test('messageType==text→false', () {
        final model = MessageModel(
          id: 'msg-002',
          senderUid: 'worker-001',
          text: 'テスト',
        );
        expect(model.isImage, isFalse);
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

      test('画像メッセージ（text空・imageUrlあり）→true', () {
        final model = MessageModel(
          id: 'msg-img',
          senderUid: 'worker-001',
          text: '',
          imageUrl: 'https://example.com/image.jpg',
          messageType: 'image',
        );
        expect(model.isNotEmpty, isTrue);
      });
    });

    group('equality', () {
      test('同一フィールドのオブジェクトは等しい', () {
        final now = DateTime(2025, 3, 15);
        final model1 = MessageModel(
          id: 'msg-001',
          senderUid: 'worker-001',
          text: 'テストメッセージ',
          createdAt: now,
        );
        final model2 = MessageModel(
          id: 'msg-001',
          senderUid: 'worker-001',
          text: 'テストメッセージ',
          createdAt: now,
        );

        expect(model1, equals(model2));
        expect(model1.hashCode, equals(model2.hashCode));
      });

      test('異なるフィールドのオブジェクトは等しくない', () {
        final model1 = MessageModel.fromMap('msg-001', TestFixtures.messageData());
        final model2 = MessageModel.fromMap('msg-002', TestFixtures.messageData(
          text: '別のメッセージ',
        ));

        expect(model1, isNot(equals(model2)));
      });
    });

    test('copyWithで指定フィールドのみ変更される', () {
      final original = MessageModel.fromMap('msg-001', TestFixtures.messageData());
      final copied = original.copyWith(text: '新しいテキスト');

      expect(copied.text, '新しいテキスト');
      expect(copied.id, original.id);
      expect(copied.senderUid, original.senderUid);
    });

    test('copyWithでimageUrl更新が反映', () {
      final original = MessageModel(
        id: 'msg-001',
        senderUid: 'worker-001',
        text: '',
        messageType: 'image',
      );
      final copied = original.copyWith(imageUrl: 'https://example.com/new.jpg');

      expect(copied.imageUrl, 'https://example.com/new.jpg');
      expect(copied.messageType, 'image');
    });

    test('toMapでimageUrl含む場合に出力', () {
      final model = MessageModel(
        id: 'msg-001',
        senderUid: 'worker-001',
        text: '',
        imageUrl: 'https://example.com/image.jpg',
        messageType: 'image',
      );
      final map = model.toMap();

      expect(map['imageUrl'], 'https://example.com/image.jpg');
      expect(map['messageType'], 'image');
      expect(map['senderUid'], 'worker-001');
    });
  });
}
