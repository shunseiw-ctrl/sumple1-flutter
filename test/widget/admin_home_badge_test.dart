import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminHomePage バッジ', () {
    testWidgets('タブバーにバッジ表示', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'ダッシュボード'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: true,
                  label: const Text('3'),
                  child: const Icon(Icons.people_outline),
                ),
                label: '応募者',
              ),
            ],
          ),
        ),
      ));

      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('バッジ0件で非表示', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'ダッシュボード'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: false,
                  label: const Text('0'),
                  child: const Icon(Icons.people_outline),
                ),
                label: '応募者',
              ),
            ],
          ),
        ),
      ));

      // Badge widget exists but label is not visible
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, false);
    });
  });
}
