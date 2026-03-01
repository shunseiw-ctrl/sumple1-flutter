import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;
  static final observer = FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logJobView(String jobId) async {
    await _analytics.logEvent(
      name: 'job_view',
      parameters: {'job_id': jobId},
    );
  }

  static Future<void> logJobApply(String jobId) async {
    await _analytics.logEvent(
      name: 'job_apply',
      parameters: {'job_id': jobId},
    );
  }

  static Future<void> logJobPost(String jobId) async {
    await _analytics.logEvent(
      name: 'job_post',
      parameters: {'job_id': jobId},
    );
  }

  static Future<void> logChatStart(String chatId) async {
    await _analytics.logEvent(
      name: 'chat_start',
      parameters: {'chat_id': chatId},
    );
  }

  static Future<void> logSearch({String? prefecture, String? keyword}) async {
    await _analytics.logEvent(
      name: 'search',
      parameters: {
        if (prefecture != null) 'prefecture': prefecture,
        if (keyword != null) 'keyword': keyword,
      },
    );
  }

  static Future<void> logFavoriteAdd(String jobId) async {
    await _analytics.logEvent(
      name: 'favorite_add',
      parameters: {'job_id': jobId},
    );
  }

  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> setUserRole(String role) async {
    await _analytics.setUserProperty(name: 'user_role', value: role);
  }
}
