import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/section_title.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('SectionTitle', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SectionTitle(title: 'テストタイトル', subtitle: 'テストサブタイトル'),
      ));

      expect(find.text('テストタイトル'), findsOneWidget);
      expect(find.text('テストサブタイトル'), findsOneWidget);
    });

    testWidgets('title has bold font weight', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const SectionTitle(title: '太字テスト', subtitle: 'サブ'),
      ));

      expect(find.text('太字テスト'), findsOneWidget);
    });
  });
}
