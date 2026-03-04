import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/job_image_slider.dart';
import 'package:sumple1/presentation/widgets/animated_page_indicator.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('JobImageSlider', () {
    testWidgets('画像0枚の場合、プレースホルダーを表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const JobImageSlider(
            imageUrls: [],
            category: '内装',
            height: 180,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // プレースホルダーのアイコンが表示される
      expect(find.byType(Icon), findsWidgets);
      // PageViewは表示されない
      expect(find.byType(PageView), findsNothing);
      // AnimatedPageIndicatorは表示されない
      expect(find.byType(AnimatedPageIndicator), findsNothing);
    });

    testWidgets('画像1枚の場合、単一画像を表示（PageViewなし）', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const JobImageSlider(
            imageUrls: ['https://example.com/img1.jpg'],
            category: '内装',
            height: 180,
          ),
        ),
      );
      await tester.pump();

      // PageViewは表示されない
      expect(find.byType(PageView), findsNothing);
      // AnimatedPageIndicatorは表示されない
      expect(find.byType(AnimatedPageIndicator), findsNothing);
    });

    testWidgets('画像2枚以上の場合、PageView+インジケーターを表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const JobImageSlider(
            imageUrls: [
              'https://example.com/img1.jpg',
              'https://example.com/img2.jpg',
              'https://example.com/img3.jpg',
            ],
            category: '内装',
            height: 180,
          ),
        ),
      );
      await tester.pump();

      // PageViewが表示される
      expect(find.byType(PageView), findsOneWidget);
      // AnimatedPageIndicatorが表示される
      expect(find.byType(AnimatedPageIndicator), findsOneWidget);
    });

    testWidgets('heroTagが設定されている場合、Hero widgetで単一画像をラップ', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const JobImageSlider(
            imageUrls: ['https://example.com/img1.jpg'],
            category: '内装',
            heroTag: 'job-hero-1',
            height: 180,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('heightパラメータが反映される', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const JobImageSlider(
            imageUrls: [],
            height: 250,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 250);
    });
  });
}
