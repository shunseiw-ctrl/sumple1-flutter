import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/pages/map_search_page.dart';

void main() {
  group('MapSearchPage ナビゲーション', () {
    testWidgets('空jobリスト→「案件がありません」メッセージ', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MapSearchPage(initialJobs: []),
      ));

      expect(find.text('地図に表示できる案件がありません'), findsOneWidget);
    });

    testWidgets('lat/lngなしのjobのみ→「案件がありません」メッセージ', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MapSearchPage(initialJobs: [
          {'data': <String, dynamic>{'title': 'テスト'}, 'docId': 'job-001'},
        ]),
      ));

      expect(find.text('地図に表示できる案件がありません'), findsOneWidget);
    });

    testWidgets('nullジョブリスト→「案件がありません」メッセージ', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MapSearchPage(initialJobs: null),
      ));

      expect(find.text('地図に表示できる案件がありません'), findsOneWidget);
    });
  });
}
