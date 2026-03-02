import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Home greeting', () {
    test('morning greeting', () {
      final hour = 9; // morning
      String greeting;
      if (hour < 12) {
        greeting = 'おはようございます';
      } else if (hour < 18) {
        greeting = 'こんにちは';
      } else {
        greeting = 'こんばんは';
      }
      expect(greeting, 'おはようございます');
    });

    test('evening greeting', () {
      final hour = 20; // evening
      String greeting;
      if (hour < 12) {
        greeting = 'おはようございます';
      } else if (hour < 18) {
        greeting = 'こんにちは';
      } else {
        greeting = 'こんばんは';
      }
      expect(greeting, 'こんばんは');
    });
  });
}
