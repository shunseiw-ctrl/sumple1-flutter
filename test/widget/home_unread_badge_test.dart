import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/test_helpers.dart';

/// BottomNavの未読バッジ表示テスト
/// （_ModernBottomNavの未読バッジロジックを単体検証）
void main() {
  // GoogleFontsのHTTP呼び出しを無効化
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BottomNav 未読メッセージバッジ', () {
    testWidgets('未読数0の場合、バッジは非表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _TestBottomNav(unreadCount: 0),
        ),
      );
      await tester.pumpAndSettle();

      // 赤いバッジコンテナは存在しない
      expect(find.byKey(const Key('unread-badge')), findsNothing);
    });

    testWidgets('未読数が1以上の場合、バッジに数値を表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _TestBottomNav(unreadCount: 5),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unread-badge')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('未読数が99超の場合、99+と表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _TestBottomNav(unreadCount: 150),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unread-badge')), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('バッジの色が赤である', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          _TestBottomNav(unreadCount: 3),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.byKey(const Key('unread-badge')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });
  });
}

/// テスト用のBottomNavバッジ表示ウィジェット
/// 実際の_ModernBottomNavと同じバッジロジックを再現
class _TestBottomNav extends StatelessWidget {
  final int unreadCount;

  const _TestBottomNav({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(Icons.search, '検索', false),
        _navItem(Icons.work_outline, 'はたらく', false),
        _navItemWithBadge(Icons.chat_bubble_outline, 'メッセージ', false),
        _navItem(Icons.payments_outlined, '売上', false),
        _navItem(Icons.person_outline, 'マイページ', false),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _navItemWithBadge(IconData icon, String label, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 26),
            if (unreadCount > 0)
              Positioned(
                right: -8,
                top: -4,
                child: Container(
                  key: const Key('unread-badge'),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
