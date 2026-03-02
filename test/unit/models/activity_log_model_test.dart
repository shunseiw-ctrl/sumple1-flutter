import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/activity_log_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ActivityLogModel', () {
    test('fromMap で正しく生成される', () {
      final data = TestFixtures.activityLogData();
      final model = ActivityLogModel.fromMap('log-001', data);

      expect(model.id, 'log-001');
      expect(model.applicationId, 'app-001');
      expect(model.actorUid, 'worker-001');
      expect(model.actorRole, 'worker');
      expect(model.eventType, 'status_change');
      expect(model.description, 'ステータスが変更されました');
    });

    test('toMap で正しく変換される', () {
      final data = TestFixtures.activityLogData(
        metadata: {'oldStatus': 'applied', 'newStatus': 'assigned'},
      );
      final model = ActivityLogModel.fromMap('log-001', data);
      final map = model.toMap();

      expect(map['applicationId'], 'app-001');
      expect(map['eventType'], 'status_change');
      expect(map['metadata'], {'oldStatus': 'applied', 'newStatus': 'assigned'});
    });

    test('equality が正しく動作する', () {
      final data = TestFixtures.activityLogData();
      final model1 = ActivityLogModel.fromMap('log-001', data);
      final model2 = ActivityLogModel.fromMap('log-001', data);
      final model3 = ActivityLogModel.fromMap('log-002', data);

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
      expect(model1, isNot(equals(model3)));
    });
  });
}
