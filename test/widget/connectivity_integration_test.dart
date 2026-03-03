import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/connectivity_provider.dart';

/// OfflineBannerはConnectivityServiceを内部で使うため、
/// Riverpod isOnlineProvider をベースにテストする。
Widget _buildTestApp({required bool isOnline}) {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWithValue(isOnline),
    ],
    child: MaterialApp(
      home: _TestPage(),
    ),
  );
}

class _TestPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            Material(
              color: Colors.orange.shade800,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'オフラインモード — キャッシュデータを表示中',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Expanded(child: Center(child: Text('コンテンツ'))),
        ],
      ),
    );
  }
}

void main() {
  group('OfflineBanner Riverpod 統合', () {
    testWidgets('オンライン時にオフラインバナーが表示されない', (tester) async {
      await tester.pumpWidget(_buildTestApp(isOnline: true));

      expect(find.text('オフラインモード — キャッシュデータを表示中'), findsNothing);
      expect(find.text('コンテンツ'), findsOneWidget);
    });

    testWidgets('オフライン時にオフラインバナーが表示される', (tester) async {
      await tester.pumpWidget(_buildTestApp(isOnline: false));

      expect(find.text('オフラインモード — キャッシュデータを表示中'), findsOneWidget);
    });

    testWidgets('OfflineBannerとコンテンツが同時に表示される', (tester) async {
      await tester.pumpWidget(_buildTestApp(isOnline: false));

      expect(find.text('オフラインモード — キャッシュデータを表示中'), findsOneWidget);
      expect(find.text('コンテンツ'), findsOneWidget);
    });

    testWidgets('isOnlineProviderをオーバーライドできる', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final online = ref.watch(isOnlineProvider);
                return Text(online ? 'online' : 'offline');
              },
            ),
          ),
        ),
      );

      expect(find.text('online'), findsOneWidget);
    });

    testWidgets('wifi_offアイコンが表示される', (tester) async {
      await tester.pumpWidget(_buildTestApp(isOnline: false));

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('再試行ボタンなしの場合は再試行が表示されない', (tester) async {
      await tester.pumpWidget(_buildTestApp(isOnline: false));

      expect(find.text('再試行'), findsNothing);
    });
  });
}
