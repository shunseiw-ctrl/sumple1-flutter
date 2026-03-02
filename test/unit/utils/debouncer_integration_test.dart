import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/debouncer.dart';

void main() {
  group('Debouncer integration', () {
    test('instance creation and disposal works normally', () {
      final debouncer = Debouncer();
      debouncer.run(() {});
      debouncer.dispose();
      // No exception
    });

    test('run after dispose does not throw', () {
      final debouncer = Debouncer();
      debouncer.dispose();
      // run after dispose should not throw
      expect(() => debouncer.run(() {}), returnsNormally);
    });
  });
}
