import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/job_card.dart';

void main() {
  Widget buildTestWidget(JobCard card) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: card),
      ),
    );
  }

  JobCard makeJobCard({String? distanceLabel}) {
    return JobCard(
      title: 'テスト案件',
      location: '東京都新宿区',
      dateText: '2025-04-01',
      priceText: '¥15000',
      badges: const [],
      showLegacyWarning: false,
      data: const {'price': '15000'},
      isOwner: false,
      onTap: () {},
      onEdit: null,
      onDelete: null,
      distanceLabel: distanceLabel,
    );
  }

  group('JobCard distanceLabel', () {
    testWidgets('distanceLabel指定時にバッジ表示', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeJobCard(distanceLabel: '1.2km')));

      expect(find.text('1.2km'), findsOneWidget);
    });

    testWidgets('distanceLabel=null時にバッジ非表示', (tester) async {
      await tester.pumpWidget(buildTestWidget(makeJobCard()));

      expect(find.text('1.2km'), findsNothing);
    });
  });
}
