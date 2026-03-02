import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_shadows.dart';

void main() {
  group('AppShadows', () {
    test('card: 2要素のBoxShadowリスト', () {
      expect(AppShadows.card, isA<List<BoxShadow>>());
      expect(AppShadows.card.length, 2);
    });

    test('elevated: 2要素', () {
      expect(AppShadows.elevated, isA<List<BoxShadow>>());
      expect(AppShadows.elevated.length, 2);
    });

    test('subtle: 1要素', () {
      expect(AppShadows.subtle, isA<List<BoxShadow>>());
      expect(AppShadows.subtle.length, 1);
    });

    test('bottomNav: 1要素', () {
      expect(AppShadows.bottomNav, isA<List<BoxShadow>>());
      expect(AppShadows.bottomNav.length, 1);
    });

    test('button: 1要素', () {
      expect(AppShadows.button, isA<List<BoxShadow>>());
      expect(AppShadows.button.length, 1);
    });

    test('card: 繰返しアクセスで同一インスタンス', () {
      final first = AppShadows.card;
      final second = AppShadows.card;
      expect(identical(first, second), isTrue);
    });
  });
}
