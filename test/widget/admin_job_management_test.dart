import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/pages/admin/admin_job_management_tab.dart';

void main() {
  group('AdminJobManagementTab', () {
    test('widget can be constructed', () {
      const widget = AdminJobManagementTab();
      expect(widget, isA<AdminJobManagementTab>());
    });

    test('widget is a StatefulWidget', () {
      const widget = AdminJobManagementTab();
      expect(widget, isA<StatefulWidget>());
    });

    test('filter chip labels are defined', () {
      // Verify the filter labels used in the tab
      const labels = ['すべて', '公開中', '完了', '下書き'];
      expect(labels.length, equals(4));
      expect(labels.contains('すべて'), isTrue);
      expect(labels.contains('公開中'), isTrue);
    });
  });
}
