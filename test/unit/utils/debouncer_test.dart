import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('executes action after default delay (300ms)', () {
      fakeAsync((async) {
        final debouncer = Debouncer();
        int callCount = 0;

        debouncer.run(() => callCount++);

        expect(callCount, 0);
        async.elapse(const Duration(milliseconds: 299));
        expect(callCount, 0);
        async.elapse(const Duration(milliseconds: 1));
        expect(callCount, 1);

        debouncer.dispose();
      });
    });

    test('only executes last action when called multiple times within delay', () {
      fakeAsync((async) {
        final debouncer = Debouncer();
        int callCount = 0;
        String lastValue = '';

        debouncer.run(() {
          callCount++;
          lastValue = 'first';
        });
        async.elapse(const Duration(milliseconds: 100));

        debouncer.run(() {
          callCount++;
          lastValue = 'second';
        });
        async.elapse(const Duration(milliseconds: 100));

        debouncer.run(() {
          callCount++;
          lastValue = 'third';
        });
        async.elapse(const Duration(milliseconds: 300));

        expect(callCount, 1);
        expect(lastValue, 'third');

        debouncer.dispose();
      });
    });

    test('cancels pending action on dispose', () {
      fakeAsync((async) {
        final debouncer = Debouncer();
        int callCount = 0;

        debouncer.run(() => callCount++);
        debouncer.dispose();

        async.elapse(const Duration(milliseconds: 500));
        expect(callCount, 0);
      });
    });

    test('dispose cleans up resources', () {
      final debouncer = Debouncer();
      debouncer.run(() {});
      debouncer.dispose();
      // No exception should be thrown
    });

    test('custom duration works (500ms)', () {
      fakeAsync((async) {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 500));
        int callCount = 0;

        debouncer.run(() => callCount++);

        async.elapse(const Duration(milliseconds: 300));
        expect(callCount, 0);
        async.elapse(const Duration(milliseconds: 200));
        expect(callCount, 1);

        debouncer.dispose();
      });
    });

    test('previous timer is cancelled before starting new one', () {
      fakeAsync((async) {
        final debouncer = Debouncer();
        int firstCallCount = 0;
        int secondCallCount = 0;

        debouncer.run(() => firstCallCount++);
        async.elapse(const Duration(milliseconds: 200));
        debouncer.run(() => secondCallCount++);
        async.elapse(const Duration(milliseconds: 300));

        expect(firstCallCount, 0);
        expect(secondCallCount, 1);

        debouncer.dispose();
      });
    });
  });
}
