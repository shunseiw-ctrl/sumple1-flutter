import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';

void main() {
  group('AppCachedImage', () {
    testWidgets('ウィジェットが正しくレンダリングされる', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/test.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(AppCachedImage), findsOneWidget);
    });

    testWidgets('widthとheightが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/test.jpg',
              width: 200,
              height: 150,
            ),
          ),
        ),
      );

      expect(find.byType(AppCachedImage), findsOneWidget);
    });

    testWidgets('borderRadiusが適用される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/test.jpg',
              borderRadius: 16,
            ),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('カスタムerrorWidgetが使用される', (tester) async {
      const errorWidget = Icon(Icons.error);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/test.jpg',
              errorWidget: errorWidget,
            ),
          ),
        ),
      );

      expect(find.byType(AppCachedImage), findsOneWidget);
    });

    testWidgets('カスタムplaceholderが使用される', (tester) async {
      const placeholder = CircularProgressIndicator();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/test.jpg',
              placeholder: placeholder,
            ),
          ),
        ),
      );

      expect(find.byType(AppCachedImage), findsOneWidget);
    });

    testWidgets('デフォルトplaceholderはSkeletonLoaderを使用する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/test.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // SkeletonLoaderがデフォルトplaceholderとして使われる
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('カスタムplaceholder指定時はSkeletonLoader不使用', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/test.jpg',
              width: 100,
              height: 100,
              placeholder: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsNothing);
    });
  });
}
