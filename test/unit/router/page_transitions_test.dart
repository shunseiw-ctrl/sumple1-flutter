import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/page_transitions.dart';

void main() {
  group('Page Transitions', () {
    test('slideUpTransition returns CustomTransitionPage', () {
      final page = slideUpTransition(
        key: const ValueKey('test'),
        child: const SizedBox(),
      );
      expect(page, isA<CustomTransitionPage<void>>());
    });

    test('fadeThroughTransition returns CustomTransitionPage', () {
      final page = fadeThroughTransition(
        key: const ValueKey('test'),
        child: const SizedBox(),
      );
      expect(page, isA<CustomTransitionPage<void>>());
    });

    test('slideRightTransition returns CustomTransitionPage', () {
      final page = slideRightTransition(
        key: const ValueKey('test'),
        child: const SizedBox(),
      );
      expect(page, isA<CustomTransitionPage<void>>());
    });

    test('slideUpTransition duration is 300ms', () {
      final page = slideUpTransition(
        key: const ValueKey('test'),
        child: const SizedBox(),
      );
      expect(page.transitionDuration, const Duration(milliseconds: 300));
    });

    test('fadeThroughTransition duration is 300ms', () {
      final page = fadeThroughTransition(
        key: const ValueKey('test'),
        child: const SizedBox(),
      );
      expect(page.transitionDuration, const Duration(milliseconds: 300));
    });

    test('slideRightTransition reverseDuration is 250ms', () {
      final page = slideRightTransition(
        key: const ValueKey('test'),
        child: const SizedBox(),
      );
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 250));
    });

    test('key is correctly set', () {
      const testKey = ValueKey('my-key');
      final page = slideUpTransition(
        key: testKey,
        child: const SizedBox(),
      );
      expect(page.key, testKey);
    });

    test('child is correctly set', () {
      const child = Text('Hello');
      final page = slideUpTransition(
        key: const ValueKey('test'),
        child: child,
      );
      expect(page.child, child);
    });
  });
}
