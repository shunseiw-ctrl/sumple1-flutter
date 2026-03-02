import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/job_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('JobModel requiredQualifications', () {
    test('requiredQualifications ありのラウンドトリップ', () {
      final data = TestFixtures.jobData();
      data['requiredQualifications'] = ['interior', 'scaffolding'];

      final model = JobModel.fromMap('job-001', data);
      expect(model.requiredQualifications, ['interior', 'scaffolding']);

      final map = model.toMap();
      expect(map['requiredQualifications'], ['interior', 'scaffolding']);

      final copied =
          model.copyWith(requiredQualifications: ['electrical']);
      expect(copied.requiredQualifications, ['electrical']);
    });

    test('requiredQualifications null の場合', () {
      final data = TestFixtures.jobData();
      // requiredQualifications は含まない
      final model = JobModel.fromMap('job-001', data);
      expect(model.requiredQualifications, isNull);

      final map = model.toMap();
      expect(map.containsKey('requiredQualifications'), isFalse);
    });
  });
}
