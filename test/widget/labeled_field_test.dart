import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/labeled_field.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('LabeledField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(buildTestApp(
        LabeledField(
          label: 'テストラベル',
          hint: 'ヒント',
          controller: controller,
          textInputAction: TextInputAction.done,
        ),
      ));

      expect(find.text('テストラベル'), findsOneWidget);
    });

    testWidgets('displays hint text in TextField', (tester) async {
      await tester.pumpWidget(buildTestApp(
        LabeledField(
          label: 'ラベル',
          hint: 'テストヒント',
          controller: controller,
          textInputAction: TextInputAction.done,
        ),
      ));

      expect(find.text('テストヒント'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      await tester.pumpWidget(buildTestApp(
        LabeledField(
          label: '入力',
          hint: 'ヒント',
          controller: controller,
          textInputAction: TextInputAction.done,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'テスト入力');
      expect(controller.text, 'テスト入力');
    });

    testWidgets('shows prefix icon when provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        LabeledField(
          label: 'アイコン',
          hint: 'ヒント',
          controller: controller,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.search,
        ),
      ));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('supports multiline with maxLines', (tester) async {
      await tester.pumpWidget(buildTestApp(
        LabeledField(
          label: '複数行',
          hint: 'ヒント',
          controller: controller,
          textInputAction: TextInputAction.done,
          maxLines: 6,
        ),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 6);
    });
  });
}
