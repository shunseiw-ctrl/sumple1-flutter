import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewService {
  static const _appCountKey = 'review_app_count';
  static const _lastPromptKey = 'review_last_prompt';
  static const _triggerCount = 3;
  static const _cooldownDays = 30;

  Future<void> onApplicationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_appCountKey) ?? 0) + 1;
    await prefs.setInt(_appCountKey, count);

    if (count >= _triggerCount && await _shouldShowReview(prefs)) {
      await _requestReview(prefs);
    }
  }

  Future<bool> _shouldShowReview(SharedPreferences prefs) async {
    final lastPrompt = prefs.getInt(_lastPromptKey);
    if (lastPrompt == null) return true;

    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastPrompt);
    final daysSince = DateTime.now().difference(lastDate).inDays;
    return daysSince >= _cooldownDays;
  }

  Future<void> _requestReview(SharedPreferences prefs) async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      await prefs.setInt(
        _lastPromptKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }
}
