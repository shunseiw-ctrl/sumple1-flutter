import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import '../helpers/test_helpers.dart';

/// AdminJobManagementTab の UIコンポーネントテスト
void main() {
  group('AdminJobManagementTab UI Components', () {
    testWidgets('空状態が正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_off_outlined, size: 48, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('案件がまだありません',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              SizedBox(height: 8),
              Text('右下のボタンから案件を投稿できます',
                style: TextStyle(fontSize: 13, color: AppColors.textHint)),
            ],
          ),
        ),
      ));

      expect(find.text('案件がまだありません'), findsOneWidget);
      expect(find.text('右下のボタンから案件を投稿できます'), findsOneWidget);
      expect(find.byIcon(Icons.work_off_outlined), findsOneWidget);
    });

    testWidgets('ジョブカードが正しく表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.ruriPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.work, color: AppColors.ruri, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('内装工事スタッフ',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.place, size: 14, color: AppColors.textHint),
                                SizedBox(width: 2),
                                Text('東京都渋谷区', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 10),
                                Icon(Icons.event, size: 14, color: AppColors.textHint),
                                SizedBox(width: 2),
                                Text('2026-03-15', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Text('\u00a530,000',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ));

      expect(find.text('内装工事スタッフ'), findsOneWidget);
      expect(find.text('東京都渋谷区'), findsOneWidget);
      expect(find.text('2026-03-15'), findsOneWidget);
      expect(find.text('\u00a530,000'), findsOneWidget);
      expect(find.byIcon(Icons.place), findsOneWidget);
      expect(find.byIcon(Icons.event), findsOneWidget);
    });
  });
}
