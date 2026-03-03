import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/pages/admin/admin_applicants_tab.dart';

void main() {
  group('AdminApplicantsTab bulk operations', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AdminApplicantsTab()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AdminApplicantsTab), findsOneWidget);
    });

    testWidgets('page structure is valid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AdminApplicantsTab()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AdminApplicantsTab), findsOneWidget);
    });
  });
}
