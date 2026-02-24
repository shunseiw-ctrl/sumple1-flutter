import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders icon, title, and description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.work_off,
              title: '案件がありません',
              description: '新しい案件が投稿されるまでお待ちください',
            ),
          ),
        ),
      );

      expect(find.text('案件がありません'), findsOneWidget);
      expect(find.text('新しい案件が投稿されるまでお待ちください'), findsOneWidget);
      expect(find.byIcon(Icons.work_off), findsOneWidget);
    });

    testWidgets('renders action button when actionText and onAction provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search,
              title: '検索結果なし',
              description: '条件を変更してください',
              actionText: '再検索',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('再検索'), findsOneWidget);

      await tester.tap(find.text('再検索'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('does not render action button when actionText is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'メッセージなし',
              description: 'まだメッセージはありません',
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('does not render action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'メッセージなし',
              description: 'まだメッセージはありません',
              actionText: 'ボタン',
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders without imagePath shows icon container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.notifications_off,
              title: '通知なし',
              description: '通知はありません',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_off), findsOneWidget);
      expect(find.text('通知なし'), findsOneWidget);
    });

    testWidgets('custom iconColor is applied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.error,
              title: 'エラー',
              description: 'エラーが発生しました',
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(icon.color, Colors.red);
    });
  });
}
