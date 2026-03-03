import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/pages/admin/admin_job_management_tab.dart';

void main() {
  group('AdminJobManagementTab', () {
    test('widget type is StatefulWidget', () {
      const widget = AdminJobManagementTab();
      expect(widget, isA<AdminJobManagementTab>());
      expect(widget.key, isNull);
    });
  });
}
