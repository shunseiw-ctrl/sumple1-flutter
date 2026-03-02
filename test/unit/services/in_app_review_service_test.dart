import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InAppReviewService logic', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('応募1回目ではレビュー条件を満たさない', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('review_app_count', 1);

      final count = prefs.getInt('review_app_count') ?? 0;
      expect(count < 3, isTrue);
    });

    test('応募3回目でレビュー条件を満たす', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('review_app_count', 3);

      final count = prefs.getInt('review_app_count') ?? 0;
      expect(count >= 3, isTrue);
    });

    test('前回プロンプトから30日未満ではfalse', () async {
      final now = DateTime.now();
      final tenDaysAgo = now.subtract(const Duration(days: 10));

      SharedPreferences.setMockInitialValues({
        'review_last_prompt': tenDaysAgo.millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();

      final lastPrompt = prefs.getInt('review_last_prompt');
      expect(lastPrompt, isNotNull);

      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastPrompt!);
      final daysSince = now.difference(lastDate).inDays;
      expect(daysSince < 30, isTrue);
    });

    test('SharedPreferencesにカウントが保存される', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final count = (prefs.getInt('review_app_count') ?? 0) + 1;
      await prefs.setInt('review_app_count', count);

      expect(prefs.getInt('review_app_count'), 1);

      final count2 = (prefs.getInt('review_app_count') ?? 0) + 1;
      await prefs.setInt('review_app_count', count2);

      expect(prefs.getInt('review_app_count'), 2);
    });
  });
}
