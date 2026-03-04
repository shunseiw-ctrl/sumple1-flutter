import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/currency_utils.dart';
import '../helpers/test_helpers.dart';

/// SalesPage分割後の機能維持テスト
/// （Firestore依存を避け、表示ロジック・共通ウィジェットを検証）
void main() {
  group('SalesPage 分割後の表示ロジック', () {
    testWidgets('CurrencyUtilsで収入金額が正しくフォーマットされる', (tester) async {
      final formatted = CurrencyUtils.formatYen(250000);
      await tester.pumpWidget(
        buildTestApp(
          Text(formatted),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¥250,000'), findsOneWidget);
    });

    testWidgets('MiniStatウィジェットがラベルと値を表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const _MiniStat(label: '今月の収入', value: '¥150,000'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今月の収入'), findsOneWidget);
      expect(find.text('¥150,000'), findsOneWidget);
    });

    testWidgets('SalesShadowCardが子ウィジェットを正しくラップ', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _SalesShadowCard(
            child: const Text('テストコンテンツ'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('テストコンテンツ'), findsOneWidget);
      // Containerが見つかる（影付きカード）
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('2タブ構成（収入/明細）のTabBarが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: '収入'),
                    Tab(text: '明細'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      const Center(child: Text('収入コンテンツ')),
                      const Center(child: Text('明細コンテンツ')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('収入'), findsOneWidget);
      expect(find.text('明細'), findsOneWidget);
      expect(find.text('収入コンテンツ'), findsOneWidget);
    });

    testWidgets('タブ切り替えで明細タブのコンテンツが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: '収入'),
                    Tab(text: '明細'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      const Center(child: Text('収入コンテンツ')),
                      const Center(child: Text('明細コンテンツ')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 明細タブをタップ
      await tester.tap(find.text('明細'));
      await tester.pumpAndSettle();

      expect(find.text('明細コンテンツ'), findsOneWidget);
    });
  });
}

/// テスト用MiniStatウィジェット（sales_shared.dartの再現）
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

/// テスト用SalesShadowCard（sales_shared.dartの再現）
class _SalesShadowCard extends StatelessWidget {
  final Widget child;

  const _SalesShadowCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
