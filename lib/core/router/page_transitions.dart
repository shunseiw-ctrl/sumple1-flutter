import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 下からスライドアップ + フェード（詳細/作成画面向け）
CustomTransitionPage<void> slideUpTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetTween = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));
      return SlideTransition(
        position: animation.drive(offsetTween),
        child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
      );
    },
  );
}

/// フェードスルー（情報ページ向け）
CustomTransitionPage<void> fadeThroughTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

/// 右からスライド（設定系向け）
CustomTransitionPage<void> slideRightTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetTween =
          Tween(begin: const Offset(0.25, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));
      return SlideTransition(
        position: animation.drive(offsetTween),
        child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
      );
    },
  );
}
