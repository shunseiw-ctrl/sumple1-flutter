import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppHaptics', () {
    late List<MethodCall> log;

    setUp(() {
      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        log.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('tap calls HapticFeedback.lightImpact', () async {
      AppHaptics.tap();
      await Future<void>.delayed(Duration.zero);
      expect(
        log.any((c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.lightImpact'),
        isTrue,
      );
    });

    test('success calls HapticFeedback.mediumImpact', () async {
      AppHaptics.success();
      await Future<void>.delayed(Duration.zero);
      expect(
        log.any((c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.mediumImpact'),
        isTrue,
      );
    });

    test('selection calls HapticFeedback.selectionClick', () async {
      AppHaptics.selection();
      await Future<void>.delayed(Duration.zero);
      expect(
        log.any((c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.selectionClick'),
        isTrue,
      );
    });

    test('warning calls HapticFeedback.heavyImpact', () async {
      AppHaptics.warning();
      await Future<void>.delayed(Duration.zero);
      expect(
        log.any((c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.heavyImpact'),
        isTrue,
      );
    });

    test('all methods can be called without exception', () {
      expect(() => AppHaptics.tap(), returnsNormally);
      expect(() => AppHaptics.success(), returnsNormally);
      expect(() => AppHaptics.selection(), returnsNormally);
      expect(() => AppHaptics.warning(), returnsNormally);
    });
  });
}
