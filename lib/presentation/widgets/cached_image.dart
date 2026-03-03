import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/extensions/build_context_extensions.dart';
import 'skeleton_loader.dart';

/// キャッシュ付きネットワーク画像ウィジェット
class AppCachedImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final effectiveMemCacheWidth = memCacheWidth ??
        (width != null ? (width! * dpr).round() : null);
    final effectiveMemCacheHeight = memCacheHeight ??
        (height != null ? (height! * dpr).round() : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: effectiveMemCacheWidth,
        memCacheHeight: effectiveMemCacheHeight,
        placeholder: (context, url) =>
            placeholder ??
            SkeletonLoader(
              width: width ?? double.infinity,
              height: height ?? 160,
              borderRadius: borderRadius,
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: context.appColors.chipUnselected,
              child: Icon(
                Icons.broken_image,
                color: context.appColors.textHint,
              ),
            ),
      ),
    );
  }
}
