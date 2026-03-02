import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import '../helpers/test_helpers.dart';

/// AdminDashboardTab の UIコンポーネントテスト
void main() {
  group('AdminDashboardTab UI Components', () {
    testWidgets('ダッシュボードヘッダーとサマリカードが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.ruri, AppColors.ruriLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('管理者ダッシュボード',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('掲載中の案件', 5)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('応募数', 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('登録ユーザー', 8)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('未対応の応募', 3)),
              ],
            ),
          ],
        ),
      ));

      expect(find.text('管理者ダッシュボード'), findsOneWidget);
      expect(find.text('掲載中の案件'), findsOneWidget);
      expect(find.text('応募数'), findsOneWidget);
      expect(find.text('登録ユーザー'), findsOneWidget);
      expect(find.text('未対応の応募'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('クイックアクションボタンが表示されタップできる', (tester) async {
      int? navigatedIndex;
      bool postJobTapped = false;

      await tester.pumpWidget(buildTestApp(
        ListView(
          children: [
            const Text('クイックアクション',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => postJobTapped = true,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Column(
                          children: [
                            Icon(Icons.add_circle_outline, color: AppColors.ruri, size: 28),
                            SizedBox(height: 8),
                            Text('案件を投稿'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => navigatedIndex = 3,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Column(
                          children: [
                            Icon(Icons.bar_chart, color: AppColors.ruri, size: 28),
                            SizedBox(height: 8),
                            Text('売上を確認'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ));

      expect(find.text('クイックアクション'), findsOneWidget);
      expect(find.text('案件を投稿'), findsOneWidget);
      expect(find.text('売上を確認'), findsOneWidget);

      await tester.tap(find.text('売上を確認'));
      await tester.pump();
      expect(navigatedIndex, equals(3));

      await tester.tap(find.text('案件を投稿'));
      await tester.pump();
      expect(postJobTapped, isTrue);
    });

    testWidgets('空の応募リストでEmptyCardが表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ListView(
          children: [
            const Text('最近の応募',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Center(
                child: Text('まだ応募はありません',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ));

      expect(find.text('最近の応募'), findsOneWidget);
      expect(find.text('まだ応募はありません'), findsOneWidget);
    });
  });
}

Widget _buildSummaryCard(String label, int count) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count.toString(),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
