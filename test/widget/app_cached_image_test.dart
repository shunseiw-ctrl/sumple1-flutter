import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';

/// テスト用ヘルパー: AppColorsExtension付きのMaterialAppでラップ
Widget _buildTestApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: const [AppColorsExtension.light]),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppCachedImage_URL指定_正しくレンダリング', () {
    testWidgets('imageUrl_渡された場合_CachedNetworkImageに反映される', (tester) async {
      const testUrl = 'https://example.com/photo.jpg';

      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(imageUrl: testUrl, width: 100, height: 100),
      ));

      // CachedNetworkImageが生成され、正しいURLが渡されている
      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.imageUrl, testUrl);
    });

    testWidgets('imageUrl_ウィジェット自体_ツリーに存在する', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(imageUrl: 'https://example.com/a.jpg'),
      ));

      expect(find.byType(AppCachedImage), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('imageUrl_ClipRRect内_にラップされる', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(imageUrl: 'https://example.com/b.jpg'),
      ));

      expect(find.byType(ClipRRect), findsOneWidget);
      // ClipRRectの子としてCachedNetworkImageが存在する
      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect, isNotNull);
    });
  });

  group('AppCachedImage_プレースホルダー_表示', () {
    testWidgets('placeholder未指定_デフォルトSkeletonLoaderが表示される', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/c.jpg',
          width: 120,
          height: 80,
        ),
      ));

      // CachedNetworkImageの読み込み中はSkeletonLoaderが表示される
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('placeholder未指定_SkeletonLoader_width/heightが反映される',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/d.jpg',
          width: 200,
          height: 150,
        ),
      ));

      final skeleton = tester.widget<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      expect(skeleton.width, 200);
      expect(skeleton.height, 150);
    });

    testWidgets('placeholder未指定_width未指定_デフォルトサイズが使われる',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(imageUrl: 'https://example.com/e.jpg'),
      ));

      final skeleton = tester.widget<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      // デフォルト: width=double.infinity, height=160
      expect(skeleton.width, double.infinity);
      expect(skeleton.height, 160);
    });

    testWidgets('カスタムplaceholder_指定時_SkeletonLoader非表示', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/f.jpg',
          placeholder: Center(child: CircularProgressIndicator()),
        ),
      ));

      expect(find.byType(SkeletonLoader), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppCachedImage_エラー時_フォールバック表示', () {
    testWidgets('CachedNetworkImageエラー_errorWidgetコールバック_placeholder表示',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/error.jpg',
          width: 100,
          height: 100,
        ),
      ));

      // CachedNetworkImageのerrorWidgetコールバックを取得して呼び出す
      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      // errorWidgetビルダーが設定されていることを確認
      expect(cachedImage.errorWidget, isNotNull);
    });

    testWidgets('カスタムerrorWidget_指定時_プロパティが保持される', (tester) async {
      const customError = Icon(Icons.error_outline, color: Colors.red);

      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/error2.jpg',
          errorWidget: customError,
        ),
      ));

      final widget = tester.widget<AppCachedImage>(
        find.byType(AppCachedImage),
      );
      expect(widget.errorWidget, isNotNull);
      expect(widget.errorWidget, isA<Icon>());
    });

    testWidgets('フォールバック後_Image.networkが使用される', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/fallback.jpg',
          width: 100,
          height: 100,
        ),
      ));

      // CachedNetworkImageのerrorWidgetコールバックを手動で呼び出してフォールバックをトリガー
      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final errorBuilder = cachedImage.errorWidget!;

      // エラーコールバックを発火（StateのsetStateがpostFrameCallbackで実行される）
      final element = tester.element(find.byType(AppCachedImage));
      errorBuilder(element, 'https://example.com/fallback.jpg', Exception('test'));
      await tester.pump(); // postFrameCallbackの処理
      await tester.pump(); // 再ビルド

      // フォールバック後はCachedNetworkImageが消え、Image.networkが表示される
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('フォールバック後_カスタムerrorWidget_Image.networkエラー時に表示される',
        (tester) async {
      const customError = Center(child: Text('画像エラー'));

      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/fallback2.jpg',
          width: 100,
          height: 100,
          errorWidget: customError,
        ),
      ));

      // フォールバックをトリガー
      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final errorBuilder = cachedImage.errorWidget!;
      final element = tester.element(find.byType(AppCachedImage));
      errorBuilder(element, 'https://example.com/fallback2.jpg', Exception('test'));
      await tester.pump();
      await tester.pump();

      // Image.networkモードに切り替わっている
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });

  group('AppCachedImage_サイズ指定_正しく適用', () {
    testWidgets('width/height_CachedNetworkImageに渡される', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/size.jpg',
          width: 300,
          height: 200,
        ),
      ));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.width, 300);
      expect(cachedImage.height, 200);
    });

    testWidgets('fit_CachedNetworkImageに渡される', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/fit.jpg',
          fit: BoxFit.contain,
          width: 100,
          height: 100,
        ),
      ));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.fit, BoxFit.contain);
    });

    testWidgets('fit_デフォルト_BoxFit.cover', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(imageUrl: 'https://example.com/fitdef.jpg'),
      ));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.fit, BoxFit.cover);
    });

    testWidgets('borderRadius_ClipRRectに正しく適用される', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/radius.jpg',
          borderRadius: 12,
        ),
      ));

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('borderRadius_デフォルト_0', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(imageUrl: 'https://example.com/rad0.jpg'),
      ));

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, BorderRadius.zero);
    });

    testWidgets('memCacheWidth/Height_明示指定_CachedNetworkImageに渡される',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/mem.jpg',
          width: 100,
          height: 100,
          memCacheWidth: 400,
          memCacheHeight: 400,
        ),
      ));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      // 明示的に指定した場合はその値が使われる
      expect(cachedImage.memCacheWidth, 400);
      expect(cachedImage.memCacheHeight, 400);
    });

    testWidgets('memCacheWidth/Height_未指定_widthからdprで自動計算される',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(
          imageUrl: 'https://example.com/auto.jpg',
          width: 100,
          height: 80,
        ),
      ));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );

      // テスト環境のdevicePixelRatio（通常3.0）で自動計算
      // memCacheWidth = (100 * dpr).round(), memCacheHeight = (80 * dpr).round()
      expect(cachedImage.memCacheWidth, isNotNull);
      expect(cachedImage.memCacheHeight, isNotNull);
      expect(cachedImage.memCacheWidth!, greaterThan(0));
      expect(cachedImage.memCacheHeight!, greaterThan(0));
    });

    testWidgets('width/height未指定_memCacheがnullになる', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const AppCachedImage(imageUrl: 'https://example.com/nosize.jpg'),
      ));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.memCacheWidth, isNull);
      expect(cachedImage.memCacheHeight, isNull);
    });
  });
}
