import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/connectivity_provider.dart';
import 'package:sumple1/presentation/widgets/offline_banner.dart';

/// OfflineBanner を Riverpod と統合してテスト
Widget _buildTestApp({required bool isOnline}) {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWithValue(isOnline),
    ],
    child: MaterialApp(
      home: const _TestPage(),
    ),
  );
}

class _TestPage extends ConsumerWidget {
  const _TestPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    return Scaffold(
      body: Column(
        children: [
          if (!isOnline) const OfflineBanner(),
          const Expanded(child: Center(child: Text('コンテンツ'))),
        ],
      ),
    );
  }
}

void main() {
  group('OfflineBanner Riverpod 統合', () {
    testWidgets('オンライン時にOfflineBannerが表示されない', (tester) async {
      await tester.pumpWidget(_buildTestApp(isOnline: true));

      expect(find.byType(OfflineBanner), findsNothing);
      expect(find.text('コンテンツ'), findsOneWidget);
    });

    testWidgets('オフライン時にOfflineBannerが表示される', (tester) async {
      await tester.pumpWidget(_buildTestApp(isOnline: false));

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('インターネットに接続されていません'), findsOneWidget);
    });

    testWidgets('OfflineBannerとコンテンツが同時に表示される', (tester) async {
      await tester.pumpWidget(_buildTestApp(isOnline: false));

      expect(find.byType(OfflineBanner), findsOneWidget);
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
