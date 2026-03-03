import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

/// ページネーション用「もっと読み込む」ボタン
class LoadMoreButton extends StatelessWidget {
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onPressed;

  const LoadMoreButton({
    super.key,
    required this.hasMore,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.expand_more, size: 20),
                label: Text(context.l10n.loadMore_showMore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appColors.primary,
                  side: BorderSide(color: context.appColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
              ),
      ),
    );
  }
}
