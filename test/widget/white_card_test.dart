import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/white_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('WhiteCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const WhiteCard(child: Text('カード内容')),
      ));

      expect(find.text('カード内容'), findsOneWidget);
    });

    testWidgets('has white Material background', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const WhiteCard(child: Text('背景テスト')),
      ));

      final materials = tester.widgetList<Material>(find.byType(Material)).toList();
      final whiteMaterial = materials.where((m) => m.color == Colors.white);
      expect(whiteMaterial, isNotEmpty);
    });
  });
}
