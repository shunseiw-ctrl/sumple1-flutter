import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/form_divider.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('FormDivider', () {
    testWidgets('renders a Divider', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const FormDivider(),
      ));

      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
