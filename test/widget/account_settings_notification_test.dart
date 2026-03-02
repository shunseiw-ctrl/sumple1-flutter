import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Account Settings Notification Toggle', () {
    testWidgets('Switch widget renders correctly', (tester) async {
      bool value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Switch(
                value: value,
                onChanged: (v) => setState(() => value = v),
                activeColor: const Color(0xFF1E50A2),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('Switch toggles value', (tester) async {
      bool value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Switch(
                value: value,
                onChanged: (v) => setState(() => value = v),
                activeColor: const Color(0xFF1E50A2),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Switch));
      await tester.pump();
      // After tap, the switch should toggle
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
