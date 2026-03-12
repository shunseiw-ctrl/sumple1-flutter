import 'package:flutter/material.dart';
import 'package:sumple1/presentation/widgets/animated_page_indicator.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';
import 'package:sumple1/presentation/widgets/job_placeholder_image.dart';

/// 案件画像スライダー
/// 0枚→プレースホルダー、1枚→Hero付き単一画像、2枚以上→スワイプ+ドットインジケーター
class JobImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final String? category;
  final String? heroTag;
  final double height;

  const JobImageSlider({
    super.key,
    required this.imageUrls,
    this.category,
    this.heroTag,
    this.height = 180,
  });

  @override
  State<JobImageSlider> createState() => _JobImageSliderState();
}

class _JobImageSliderState extends State<JobImageSlider> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (urls.isEmpty)
            JobPlaceholderImage(category: widget.category, iconSize: 48)
          else if (urls.length == 1)
            _singleImage(context, urls.first)
          else
            _pageView(context, urls),

          // グラデーションオーバーレイ
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),

          // ドットインジケーター（2枚以上の場合）
          if (urls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: AnimatedPageIndicator(
                pageCount: urls.length,
                currentPage: _currentPage,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _singleImage(BuildContext context, String url) {
    final image = AppCachedImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: JobPlaceholderImage(category: widget.category, iconSize: 48),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: image);
    }
    return image;
  }

  Widget _pageView(BuildContext context, List<String> urls) {
    return PageView.builder(
      itemCount: urls.length,
      onPageChanged: (page) => setState(() => _currentPage = page),
      itemBuilder: (context, index) {
        return AppCachedImage(
          imageUrl: urls[index],
          fit: BoxFit.cover,
          errorWidget: JobPlaceholderImage(category: widget.category, iconSize: 48),
        );
      },
    );
  }

}
