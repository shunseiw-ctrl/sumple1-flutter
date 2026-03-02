import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';

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
                label: const Text('もっと表示'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ruri,
                  side: const BorderSide(color: AppColors.ruri),
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
