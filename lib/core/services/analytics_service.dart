import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/logger.dart';

/// Firebase Analytics のイベント管理
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // --- ユーザー行動 ---

  static Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    Logger.debug('Analytics: sign_up', tag: 'Analytics', data: {'method': method});
  }

  static Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    Logger.debug('Analytics: login', tag: 'Analytics', data: {'method': method});
  }

  static Future<void> logProfileComplete() async {
    await _analytics.logEvent(name: 'profile_complete');
  }

  // --- 求人関連 ---

  static Future<void> logJobView({required String jobId}) async {
    await _analytics.logEvent(
      name: 'job_view',
      parameters: {'job_id': jobId},
    );
  }

  static Future<void> logJobSearch({String? prefecture, String? keyword}) async {
    await _analytics.logEvent(
      name: 'job_search',
      parameters: {
        if (prefecture != null) 'prefecture': prefecture,
        if (keyword != null) 'keyword': keyword,
      },
    );
  }

  static Future<void> logJobApply({required String jobId}) async {
    await _analytics.logEvent(
      name: 'job_apply',
      parameters: {'job_id': jobId},
    );
  }

  static Future<void> logJobPost({required String jobId}) async {
    await _analytics.logEvent(
      name: 'job_post',
      parameters: {'job_id': jobId},
    );
  }

  // --- コミュニケーション ---

  static Future<void> logChatStart({required String applicationId}) async {
    await _analytics.logEvent(
      name: 'chat_start',
      parameters: {'application_id': applicationId},
    );
  }

  static Future<void> logChatMessageSent() async {
    await _analytics.logEvent(name: 'chat_message_sent');
  }

  // --- 収益 ---

  static Future<void> logEarningViewed({required String earningId}) async {
    await _analytics.logEvent(
      name: 'earning_viewed',
      parameters: {'earning_id': earningId},
    );
  }

  // --- エンゲージメント ---

  static Future<void> logFavoriteAdd({required String jobId}) async {
    await _analytics.logEvent(
      name: 'favorite_add',
      parameters: {'job_id': jobId},
    );
  }

  static Future<void> logNotificationOpen({String? type}) async {
    await _analytics.logEvent(
      name: 'notification_open',
      parameters: {if (type != null) 'type': type},
    );
  }

  // --- ユーザープロパティ ---

  static Future<void> setUserRole(String role) async {
    await _analytics.setUserProperty(name: 'user_role', value: role);
  }

  static Future<void> setPrefecture(String prefecture) async {
    await _analytics.setUserProperty(name: 'prefecture', value: prefecture);
  }

  static Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }
}
