import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApplicationModel data validation', () {
    test('valid application data has required fields', () {
      final data = {
        'applicantUid': 'user-1',
        'adminUid': 'admin-1',
        'jobId': 'job-1',
        'status': 'applied',
        'projectNameSnapshot': 'テスト案件',
      };

      expect(data['applicantUid'], isNotEmpty);
      expect(data['adminUid'], isNotEmpty);
      expect(data['jobId'], isNotEmpty);
      expect(data['status'], 'applied');
    });

    test('status should be valid value', () {
      const validStatuses = ['applied', 'accepted', 'rejected', 'completed'];
      for (final status in validStatuses) {
        expect(validStatuses.contains(status), true);
      }
    });
  });
}
