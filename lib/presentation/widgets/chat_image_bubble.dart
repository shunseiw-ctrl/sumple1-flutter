import 'package:flutter/material.dart';

import '../../core/extensions/build_context_extensions.dart';
import 'cached_image.dart';

/// 画像メッセージバブル
class ChatImageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMine;
  final String? caption;
  final VoidCallback? onTap;

  const ChatImageBubble({
    super.key,
    required this.imageUrl,
    required this.isMine,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.7;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF7BC67E) : context.appColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCachedImage(
              imageUrl: imageUrl,
              width: maxWidth,
              height: maxWidth * 0.75,
              fit: BoxFit.cover,
            ),
            if (caption != null && caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  caption!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isMine ? Colors.white : context.appColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
