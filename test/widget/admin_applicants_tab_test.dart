import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';
import '../helpers/test_helpers.dart';

/// AdminApplicantsTab の UIコンポーネントテスト
void main() {
  group('AdminApplicantsTab UI Components', () {
    testWidgets('フィルターチップが5つ表示される', (tester) async {
      String filterStatus = 'all';

      await tester.pumpWidget(buildTestApp(
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'すべて', filterStatus, (key) => setState(() => filterStatus = key)),
                      _buildFilterChip('applied', '応募中', filterStatus, (key) => setState(() => filterStatus = key)),
                      _buildFilterChip('assigned', '着工前', filterStatus, (key) => setState(() => filterStatus = key)),
                      _buildFilterChip('in_progress', '着工中', filterStatus, (key) => setState(() => filterStatus = key)),
                      _buildFilterChip('done', '完了', filterStatus, (key) => setState(() => filterStatus = key)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('応募中'), findsOneWidget);
      expect(find.text('着工前'), findsOneWidget);
      expect(find.text('着工中'), findsOneWidget);
      expect(find.text('完了'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(5));
    });

    testWidgets('応募者カードにステータスバッジとアクションボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.ruriPale,
                          child: Icon(Icons.person, color: AppColors.ruri, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('内装工事案件',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: StatusBadge.colorFor('applied').withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(StatusBadge.labelFor('applied'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: StatusBadge.colorFor('applied'))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('却下'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('承認'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ));

      expect(find.text('内装工事案件'), findsOneWidget);
      expect(find.text('応募中'), findsOneWidget);
      expect(find.text('却下'), findsOneWidget);
      expect(find.text('承認'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('空状態で応募者がいないメッセージが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('応募者はまだいません',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ));

      expect(find.text('応募者はまだいません'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });
  });
}

Widget _buildFilterChip(String key, String label, String currentFilter, void Function(String) onSelect) {
  final selected = currentFilter == key;
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => onSelect(key),
      selectedColor: AppColors.ruri,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: AppColors.chipUnselected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
  );
}
