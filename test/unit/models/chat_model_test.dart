import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/chat_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ChatModel', () {
    group('fromMap', () {
      test('完全なデータで正しく生成される', () {
        final data = TestFixtures.chatData(
          lastMessageText: 'こんにちは',
          lastMessageSenderUid: 'worker-001',
          unreadCountApplicant: 3,
          unreadCountAdmin: 1,
        );
        final model = ChatModel.fromMap('chat-001', data);

        expect(model.id, 'chat-001');
        expect(model.applicationId, 'app-001');
        expect(model.applicantUid, 'worker-001');
        expect(model.adminUid, 'admin-001');
        expect(model.jobId, 'job-001');
        expect(model.titleSnapshot, '内装工事案件');
        expect(model.lastMessageText, 'こんにちは');
        expect(model.lastMessageSenderUid, 'worker-001');
        expect(model.unreadCountApplicant, 3);
        expect(model.unreadCountAdmin, 1);
      });

      test('必須フィールドが欠落した場合のデフォルト値', () {
        final model = ChatModel.fromMap('chat-002', {});

        expect(model.applicationId, '');
        expect(model.applicantUid, '');
        expect(model.adminUid, '');
        expect(model.jobId, '');
        expect(model.titleSnapshot, 'チャット');
        expect(model.unreadCountApplicant, 0);
        expect(model.unreadCountAdmin, 0);
      });

      test('titleSnapshotが未設定なら「チャット」', () {
        final model = ChatModel.fromMap('chat-003', {
          'titleSnapshot': null,
        });
        expect(model.titleSnapshot, 'チャット');
      });

      test('unreadCountが文字列でもパースされる', () {
        final model = ChatModel.fromMap('chat-004', {
          ...TestFixtures.chatData(),
          'unreadCountApplicant': '5',
          'unreadCountAdmin': '10',
        });

        expect(model.unreadCountApplicant, 5);
        expect(model.unreadCountAdmin, 10);
      });

      test('不正なunreadCountはデフォルト0', () {
        final model = ChatModel.fromMap('chat-005', {
          ...TestFixtures.chatData(),
          'unreadCountApplicant': 'abc',
          'unreadCountAdmin': null,
        });

        expect(model.unreadCountApplicant, 0);
        expect(model.unreadCountAdmin, 0);
      });
    });

    group('getUnreadCount', () {
      late ChatModel model;

      setUp(() {
        model = ChatModel.fromMap('chat-001', TestFixtures.chatData(
          unreadCountApplicant: 3,
          unreadCountAdmin: 7,
        ));
      });

      test('応募者UIDで応募者の未読数を返す', () {
        expect(model.getUnreadCount('worker-001'), 3);
      });

      test('管理者UIDで管理者の未読数を返す', () {
        expect(model.getUnreadCount('admin-001'), 7);
      });

      test('無関係なUIDでは0を返す', () {
        expect(model.getUnreadCount('other-user'), 0);
      });
    });

    group('isApplicant / isAdmin / isParticipant', () {
      late ChatModel model;

      setUp(() {
        model = ChatModel.fromMap('chat-001', TestFixtures.chatData());
      });

      test('isApplicantは応募者UIDで真', () {
        expect(model.isApplicant('worker-001'), isTrue);
        expect(model.isApplicant('admin-001'), isFalse);
      });

      test('isAdminは管理者UIDで真', () {
        expect(model.isAdmin('admin-001'), isTrue);
        expect(model.isAdmin('worker-001'), isFalse);
      });

      test('isParticipantは当事者で真', () {
        expect(model.isParticipant('worker-001'), isTrue);
        expect(model.isParticipant('admin-001'), isTrue);
        expect(model.isParticipant('other'), isFalse);
      });
    });

    group('hasLastMessage', () {
      test('メッセージがあればtrue', () {
        final model = ChatModel.fromMap('chat-001', TestFixtures.chatData(
          lastMessageText: 'メッセージ',
        ));
        expect(model.hasLastMessage, isTrue);
      });

      test('メッセージがnullならfalse', () {
        final model = ChatModel.fromMap('chat-002', TestFixtures.chatData());
        expect(model.hasLastMessage, isFalse);
      });

      test('空文字列ならfalse', () {
        final model = ChatModel.fromMap('chat-003', TestFixtures.chatData(
          lastMessageText: '',
        ));
        expect(model.hasLastMessage, isFalse);
      });
    });

    group('copyWith', () {
      test('指定フィールドのみ変更される', () {
        final original = ChatModel.fromMap('chat-001', TestFixtures.chatData());
        final copied = original.copyWith(titleSnapshot: '変更後');

        expect(copied.titleSnapshot, '変更後');
        expect(copied.id, original.id);
        expect(copied.applicationId, original.applicationId);
      });
    });

    group('equality', () {
      test('同一フィールドのオブジェクトは等しい', () {
        final now = DateTime(2025, 3, 15);
        final model1 = ChatModel(
          id: 'chat-001',
          applicationId: 'app-001',
          applicantUid: 'worker-001',
          adminUid: 'admin-001',
          jobId: 'job-001',
          titleSnapshot: '内装工事案件',
          lastMessageText: 'こんにちは',
          lastMessageSenderUid: 'worker-001',
          lastMessageAt: now,
          unreadCountApplicant: 3,
          unreadCountAdmin: 1,
          createdAt: now,
          updatedAt: now,
        );
        final model2 = ChatModel(
          id: 'chat-001',
          applicationId: 'app-001',
          applicantUid: 'worker-001',
          adminUid: 'admin-001',
          jobId: 'job-001',
          titleSnapshot: '内装工事案件',
          lastMessageText: 'こんにちは',
          lastMessageSenderUid: 'worker-001',
          lastMessageAt: now,
          unreadCountApplicant: 3,
          unreadCountAdmin: 1,
          createdAt: now,
          updatedAt: now,
        );

        expect(model1, equals(model2));
        expect(model1.hashCode, equals(model2.hashCode));
      });

      test('異なるフィールドのオブジェクトは等しくない', () {
        final model1 = ChatModel.fromMap('chat-001', TestFixtures.chatData());
        final model2 = ChatModel.fromMap('chat-002', TestFixtures.chatData(
          titleSnapshot: '別の案件',
        ));

        expect(model1, isNot(equals(model2)));
      });
    });

    test('toStringに主要情報が含まれる', () {
      final model = ChatModel.fromMap('chat-001', TestFixtures.chatData(
        lastMessageText: 'テスト',
      ));
      final str = model.toString();
      expect(str, contains('chat-001'));
      expect(str, contains('内装工事案件'));
    });
  });
}
