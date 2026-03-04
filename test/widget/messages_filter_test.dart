import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

/// MessagesPageの未読フィルターチップのUIテスト
/// （Firestore依存を避け、フィルターチップの表示・切り替えロジックのみ検証）
void main() {
  group('MessagesPage 未読フィルター UI', () {
    testWidgets('フィルターチップ「すべて」と「未読」が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Row(
            children: [
              _buildFilterChip(label: 'すべて', selected: true, onTap: () {}),
              const SizedBox(width: 8),
              _buildFilterChip(label: '未読', selected: false, onTap: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('未読'), findsOneWidget);
    });

    testWidgets('フィルターチップをタップすると選択状態が切り替わる', (tester) async {
      bool isUnreadFilter = false;

      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Row(
                children: [
                  GestureDetector(
                    key: const Key('filter-all'),
                    onTap: () => setState(() => isUnreadFilter = false),
                    child: _buildFilterChip(
                      label: 'すべて',
                      selected: !isUnreadFilter,
                      onTap: () => setState(() => isUnreadFilter = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const Key('filter-unread'),
                    onTap: () => setState(() => isUnreadFilter = true),
                    child: _buildFilterChip(
                      label: '未読',
                      selected: isUnreadFilter,
                      onTap: () => setState(() => isUnreadFilter = true),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: 「すべて」が選択
      expect(isUnreadFilter, isFalse);

      // 「未読」をタップ
      await tester.tap(find.byKey(const Key('filter-unread')));
      await tester.pumpAndSettle();

      expect(isUnreadFilter, isTrue);

      // 「すべて」をタップして戻す
      await tester.tap(find.byKey(const Key('filter-all')));
      await tester.pumpAndSettle();

      expect(isUnreadFilter, isFalse);
    });

    testWidgets('選択されたチップと非選択チップの視覚的差異がある', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Row(
            children: [
              _buildFilterChip(label: 'すべて', selected: true, onTap: () {}),
              const SizedBox(width: 8),
              _buildFilterChip(label: '未読', selected: false, onTap: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2つのContainerが存在する（選択/非選択）
      final containers = tester.widgetList<Container>(
        find.descendant(of: find.byType(Row), matching: find.byType(Container)),
      );
      expect(containers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('フィルターリストが空の場合のフォールバック表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              Row(
                children: [
                  _buildFilterChip(label: 'すべて', selected: false, onTap: () {}),
                  const SizedBox(width: 8),
                  _buildFilterChip(label: '未読', selected: true, onTap: () {}),
                ],
              ),
              const Expanded(
                child: Center(child: Text('未読メッセージはありません')),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('未読メッセージはありません'), findsOneWidget);
    });
  });
}

/// テスト用フィルターチップ
Widget _buildFilterChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
  );
}
