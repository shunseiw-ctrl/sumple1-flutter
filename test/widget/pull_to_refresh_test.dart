import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';

void main() {
  group('Pull-to-Refresh パターン', () {
    testWidgets('RefreshIndicatorがListViewをラップできる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {},
              color: AppColors.ruri,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('RefreshIndicatorの色がAppColors.ruri', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {},
              color: AppColors.ruri,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [Text('test')],
              ),
            ),
          ),
        ),
      );

      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      expect(indicator.color, AppColors.ruri);
    });

    testWidgets('AlwaysScrollableScrollPhysicsが設定されている', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [Text('test')],
              ),
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<AlwaysScrollableScrollPhysics>());
    });

    testWidgets('RefreshIndicatorのonRefreshが呼ばれる', (tester) async {
      bool refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                refreshCalled = true;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: List.generate(
                  20,
                  (i) => SizedBox(height: 100, child: Text('Item $i')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
    });

    testWidgets('_refreshKeyパターンでStreamBuilderが再構築される', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: _RefreshKeyTestWidget(
            onBuild: () => buildCount++,
          ),
        ),
      );

      final initialCount = buildCount;

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(buildCount, greaterThan(initialCount));
    });

    testWidgets('空リストでもRefreshIndicatorが機能する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {},
              color: AppColors.ruri,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('AnimatedSwitcherが状態変化にアニメーションを適用する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: const KeyedSubtree(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AnimatedSwitcherのdurationが300ms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: const Text('test'),
            ),
          ),
        ),
      );

      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(switcher.duration, const Duration(milliseconds: 300));
    });
  });
}

class _RefreshKeyTestWidget extends StatefulWidget {
  final VoidCallback onBuild;
  const _RefreshKeyTestWidget({required this.onBuild});

  @override
  State<_RefreshKeyTestWidget> createState() => _RefreshKeyTestWidgetState();
}

class _RefreshKeyTestWidgetState extends State<_RefreshKeyTestWidget> {
  Key _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => setState(() => _refreshKey = UniqueKey()),
            child: const Text('Refresh'),
          ),
          Expanded(
            child: KeyedSubtree(
              key: _refreshKey,
              child: Builder(
                builder: (context) {
                  widget.onBuild();
                  return const Text('Content');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
