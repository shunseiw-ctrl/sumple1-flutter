import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

/// ProfilePageのワーカー統計カードのUIテスト
void main() {
  group('ProfilePage ワーカー統計カード', () {
    testWidgets('完了案件数・評価・スコアが正しく表示される', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const _WorkerStatsCard(
            completedJobs: 42,
            rating: 4.8,
            qualityScore: 85,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('ラベルが正しく表示される', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const _WorkerStatsCard(
            completedJobs: 0,
            rating: 0.0,
            qualityScore: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('完了案件'), findsOneWidget);
      expect(find.text('評価'), findsOneWidget);
      expect(find.text('スコア'), findsOneWidget);
    });

    testWidgets('ローディング時にプログレスインジケーターを表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const _WorkerStatsCardLoading(),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

/// テスト用のワーカー統計カード
class _WorkerStatsCard extends StatelessWidget {
  final int completedJobs;
  final double rating;
  final int qualityScore;

  const _WorkerStatsCard({
    required this.completedJobs,
    required this.rating,
    required this.qualityScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(value: completedJobs.toString(), label: '完了案件'),
            _StatItem(value: rating.toString(), label: '評価'),
            _StatItem(value: qualityScore.toString(), label: 'スコア'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _WorkerStatsCardLoading extends StatelessWidget {
  const _WorkerStatsCardLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
