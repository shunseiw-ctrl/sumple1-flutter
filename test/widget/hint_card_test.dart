import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/hint_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('HintCard', () {
    testWidgets('displays title and body', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const HintCard(title: 'ヒント', body: 'ヒントの説明文'),
      ));

      expect(find.text('ヒント'), findsOneWidget);
      expect(find.text('ヒントの説明文'), findsOneWidget);
    });

    testWidgets('renders with amber background', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const HintCard(title: 'テスト', body: '本文'),
      ));

      expect(find.text('テスト'), findsOneWidget);
      expect(find.text('本文'), findsOneWidget);
    });
  });
}
