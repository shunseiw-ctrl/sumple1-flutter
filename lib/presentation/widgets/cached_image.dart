import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/extensions/build_context_extensions.dart';
import '../../core/utils/logger.dart';
import 'skeleton_loader.dart';

/// キャッシュ付きネットワーク画像ウィジェット
/// CachedNetworkImage失敗時はImage.networkにフォールバック
class AppCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  State<AppCachedImage> createState() => _AppCachedImageState();
}

class _AppCachedImageState extends State<AppCachedImage> {
  bool _useFallback = false;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final effectiveMemCacheWidth = widget.memCacheWidth ??
        (widget.width != null ? (widget.width! * dpr).round() : null);
    final effectiveMemCacheHeight = widget.memCacheHeight ??
        (widget.height != null ? (widget.height! * dpr).round() : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: _useFallback
          ? _buildNetworkFallback(effectiveMemCacheWidth, effectiveMemCacheHeight)
          : CachedNetworkImage(
              imageUrl: widget.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              memCacheWidth: effectiveMemCacheWidth,
              memCacheHeight: effectiveMemCacheHeight,
              placeholder: (context, url) =>
                  widget.placeholder ??
                  SkeletonLoader(
                    width: widget.width ?? double.infinity,
                    height: widget.height ?? 160,
                    borderRadius: widget.borderRadius,
                  ),
              errorWidget: (context, url, error) {
                Logger.warning(
                  'CachedNetworkImage failed, falling back to Image.network',
                  tag: 'AppCachedImage',
                  data: {'error': '$error', 'url': url.substring(0, url.length.clamp(0, 80))},
                );
                // 次フレームでImage.networkにフォールバック
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _useFallback = true);
                });
                return widget.placeholder ??
                    SkeletonLoader(
                      width: widget.width ?? double.infinity,
                      height: widget.height ?? 160,
                      borderRadius: widget.borderRadius,
                    );
              },
            ),
    );
  }

  Widget _buildNetworkFallback(int? cacheWidth, int? cacheHeight) {
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ??
            SkeletonLoader(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 160,
              borderRadius: widget.borderRadius,
            );
      },
      errorBuilder: (context, error, stackTrace) {
        Logger.error(
          'Image.network also failed',
          tag: 'AppCachedImage',
          data: {'error': '$error', 'url': widget.imageUrl.substring(0, widget.imageUrl.length.clamp(0, 80))},
        );
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: context.appColors.chipUnselected,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: context.appColors.textHint),
                ],
              ),
            );
      },
    );
  }
}
