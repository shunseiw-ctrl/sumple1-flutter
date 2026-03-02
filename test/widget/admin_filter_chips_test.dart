import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/admin_filter_chips.dart';

void main() {
  group('AdminFilterChips', () {
    testWidgets('フィルタ選択→onSelected発火', (tester) async {
      String? selectedKey;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdminFilterChips(
            selectedKey: 'all',
            options: const {
              'all': 'すべて',
              'applied': '応募中',
              'done': '完了',
            },
            onSelected: (key) => selectedKey = key,
          ),
        ),
      ));

      // すべてのチップが表示される
      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('応募中'), findsOneWidget);
      expect(find.text('完了'), findsOneWidget);

      // '応募中'をタップ
      await tester.tap(find.text('応募中'));
      await tester.pumpAndSettle();

      expect(selectedKey, 'applied');
    });

    testWidgets('選択済みチップのスタイル変化', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AdminFilterChips(
            selectedKey: 'applied',
            options: const {
              'all': 'すべて',
              'applied': '応募中',
            },
            onSelected: (_) {},
          ),
        ),
      ));

      // ChoiceChipが2つ存在
      final chips = find.byType(ChoiceChip);
      expect(chips, findsNWidgets(2));

      // 'applied'が選択されている
      final appliedChip = tester.widget<ChoiceChip>(chips.at(1));
      expect(appliedChip.selected, true);

      // 'all'は未選択
      final allChip = tester.widget<ChoiceChip>(chips.at(0));
      expect(allChip.selected, false);
    });
  });
}
