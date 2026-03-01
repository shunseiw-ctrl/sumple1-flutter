import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/application_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ApplicationModel', () {
    group('fromMap', () {
      test('完全なデータで正しく生成される', () {
        final data = TestFixtures.applicationData(
          projectNameSnapshot: '新宿内装工事',
        );
        final model = ApplicationModel.fromMap('app-001', data);

        expect(model.id, 'app-001');
        expect(model.applicantUid, 'worker-001');
        expect(model.adminUid, 'admin-001');
        expect(model.jobId, 'job-001');
        expect(model.status, 'applied');
        expect(model.projectNameSnapshot, '新宿内装工事');
      });

      test('必須フィールドが欠落した場合は空文字列', () {
        final model = ApplicationModel.fromMap('app-002', {});

        expect(model.applicantUid, '');
        expect(model.adminUid, '');
        expect(model.jobId, '');
        expect(model.status, '');
      });

      test('nullフィールドが安全に処理される', () {
        final model = ApplicationModel.fromMap('app-003', {
          'applicantUid': null,
          'adminUid': null,
          'status': null,
          'projectNameSnapshot': null,
        });

        expect(model.applicantUid, '');
        expect(model.projectNameSnapshot, isNull);
      });

      test('DateTimeフィールドが正しく変換される', () {
        final now = DateTime(2025, 3, 15);
        final model = ApplicationModel.fromMap('app-004', {
          ...TestFixtures.applicationData(),
          'createdAt': now,
          'updatedAt': now,
        });

        expect(model.createdAt, now);
        expect(model.updatedAt, now);
      });

      test('不正なDateTime型はnullになる', () {
        final model = ApplicationModel.fromMap('app-005', {
          ...TestFixtures.applicationData(),
          'createdAt': 'not-a-date',
          'updatedAt': 12345,
        });

        expect(model.createdAt, isNull);
        expect(model.updatedAt, isNull);
      });
    });

    group('displayTitle', () {
      test('projectNameSnapshotが最優先', () {
        final model = ApplicationModel.fromMap('app-001', {
          ...TestFixtures.applicationData(
            projectNameSnapshot: 'プロジェクト名',
            jobTitleSnapshot: '案件名',
            titleSnapshot: 'タイトル',
          ),
        });
        expect(model.displayTitle, 'プロジェクト名');
      });

      test('projectNameがnullならjobTitleSnapshot', () {
        final model = ApplicationModel.fromMap('app-001', {
          ...TestFixtures.applicationData(
            jobTitleSnapshot: '案件名',
            titleSnapshot: 'タイトル',
          ),
        });
        expect(model.displayTitle, '案件名');
      });

      test('projectNameとjobTitleがnullならtitleSnapshot', () {
        final model = ApplicationModel.fromMap('app-001', {
          ...TestFixtures.applicationData(
            titleSnapshot: 'タイトル',
          ),
        });
        expect(model.displayTitle, 'タイトル');
      });

      test('全てnullならデフォルト「案件」', () {
        final model = ApplicationModel.fromMap('app-001', {
          ...TestFixtures.applicationData(),
        });
        expect(model.displayTitle, '案件');
      });
    });

    group('isApplicant / isAdmin / isParticipant', () {
      late ApplicationModel model;

      setUp(() {
        model = ApplicationModel.fromMap('app-001', TestFixtures.applicationData());
      });

      test('isApplicantは応募者UIDで真', () {
        expect(model.isApplicant('worker-001'), isTrue);
        expect(model.isApplicant('admin-001'), isFalse);
        expect(model.isApplicant('other'), isFalse);
      });

      test('isAdminは管理者UIDで真', () {
        expect(model.isAdmin('admin-001'), isTrue);
        expect(model.isAdmin('worker-001'), isFalse);
      });

      test('isParticipantは応募者または管理者で真', () {
        expect(model.isParticipant('worker-001'), isTrue);
        expect(model.isParticipant('admin-001'), isTrue);
        expect(model.isParticipant('other'), isFalse);
      });
    });

    group('copyWith', () {
      test('指定フィールドのみ変更される', () {
        final original = ApplicationModel.fromMap(
          'app-001',
          TestFixtures.applicationData(projectNameSnapshot: '元の名前'),
        );
        final copied = original.copyWith(status: 'approved');

        expect(copied.status, 'approved');
        expect(copied.id, original.id);
        expect(copied.applicantUid, original.applicantUid);
        expect(copied.projectNameSnapshot, '元の名前');
      });

      test('全フィールドをコピーできる', () {
        final original = ApplicationModel.fromMap('app-001', TestFixtures.applicationData());
        final copied = original.copyWith(
          id: 'new-id',
          applicantUid: 'new-worker',
          adminUid: 'new-admin',
          jobId: 'new-job',
        );

        expect(copied.id, 'new-id');
        expect(copied.applicantUid, 'new-worker');
        expect(copied.adminUid, 'new-admin');
        expect(copied.jobId, 'new-job');
      });
    });

    test('toStringに主要情報が含まれる', () {
      final model = ApplicationModel.fromMap(
        'app-001',
        TestFixtures.applicationData(projectNameSnapshot: 'テスト案件'),
      );
      final str = model.toString();
      expect(str, contains('app-001'));
      expect(str, contains('テスト案件'));
      expect(str, contains('applied'));
    });
  });
}
