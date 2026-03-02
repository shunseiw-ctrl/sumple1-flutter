import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analyticsInstance;
  static FirebaseAnalytics get _analytics {
    _analyticsInstance ??= FirebaseAnalytics.instance;
    return _analyticsInstance!;
  }
  static FirebaseAnalyticsObserver? _observerInstance;
  static FirebaseAnalyticsObserver get observer {
    _observerInstance ??= FirebaseAnalyticsObserver(analytics: _analytics);
    return _observerInstance!;
  }

  // --- 画面表示 ---

  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (_) {
      // Firebase 未初期化の場合は無視（テスト環境等）
    }
  }

  // --- 案件関連 ---

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

  // --- チャット ---

  static Future<void> logChatStart(String chatId) async {
    await _analytics.logEvent(
      name: 'chat_start',
      parameters: {'chat_id': chatId},
    );
  }

  static Future<void> logChatMessage(String chatId) async {
    await _analytics.logEvent(
      name: 'chat_message',
      parameters: {'chat_id': chatId},
    );
  }

  // --- 検索 ---

  static Future<void> logSearch({String? prefecture, String? keyword}) async {
    await _analytics.logEvent(
      name: 'search',
      parameters: {
        if (prefecture != null) 'prefecture': prefecture,
        if (keyword != null) 'keyword': keyword,
      },
    );
  }

  // --- お気に入り ---

  static Future<void> logFavoriteAdd(String jobId) async {
    await _analytics.logEvent(
      name: 'favorite_add',
      parameters: {'job_id': jobId},
    );
  }

  static Future<void> logFavoriteRemove(String jobId) async {
    await _analytics.logEvent(
      name: 'favorite_remove',
      parameters: {'job_id': jobId},
    );
  }

  // --- お問い合わせ ---

  static Future<void> logContactSubmit() async {
    await _analytics.logEvent(name: 'contact_submit');
  }

  // --- 売上 ---

  static Future<void> logEarningCreate(String earningId) async {
    await _analytics.logEvent(
      name: 'earning_create',
      parameters: {'earning_id': earningId},
    );
  }

  // --- プロフィール ---

  static Future<void> logProfileEdit() async {
    await _analytics.logEvent(name: 'profile_edit');
  }

  // --- チェックイン ---

  static Future<void> logCheckIn(String applicationId) async {
    await _analytics.logEvent(
      name: 'check_in',
      parameters: {'application_id': applicationId},
    );
  }

  static Future<void> logCheckOut(String applicationId) async {
    await _analytics.logEvent(
      name: 'check_out',
      parameters: {'application_id': applicationId},
    );
  }

  // --- Stripe ---

  static Future<void> logStripeOnboarding() async {
    await _analytics.logEvent(name: 'stripe_onboarding');
  }

  // --- 通知 ---

  static Future<void> logNotificationOpen(String type) async {
    await _analytics.logEvent(
      name: 'notification_open',
      parameters: {'type': type},
    );
  }

  // --- 認証 ---

  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // --- ユーザー属性 ---

  static Future<void> setUserRole(String role) async {
    await _analytics.setUserProperty(name: 'user_role', value: role);
  }

  static Future<void> setUserId(String uid) async {
    await _analytics.setUserId(id: uid);
  }

  static Future<void> setUserPrefecture(String prefecture) async {
    await _analytics.setUserProperty(name: 'user_prefecture', value: prefecture);
  }

  // --- 紹介コード ---

  static Future<void> logReferralCreate() async {
    try {
      await _analytics.logEvent(name: 'referral_create');
    } catch (_) {}
  }

  static Future<void> logReferralApply(String code) async {
    try {
      await _analytics.logEvent(
        name: 'referral_apply',
        parameters: {'code': code},
      );
    } catch (_) {}
  }

  // --- シェア ---

  static Future<void> logShareJob(String jobId) async {
    try {
      await _analytics.logEvent(
        name: 'share_job',
        parameters: {'job_id': jobId},
      );
    } catch (_) {}
  }

  static Future<void> logShareReferral() async {
    try {
      await _analytics.logEvent(name: 'share_referral');
    } catch (_) {}
  }

  // --- lastActive ---

  static Future<void> logLastActive() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return;
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .set({'lastActiveAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (_) {}
  }
}
