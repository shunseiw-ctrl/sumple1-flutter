/// アプリ全体のルートパス定数
class RoutePaths {
  RoutePaths._();

  // --- トップレベル ---
  static const String home = '/';
  static const String login = '/login';
  static const String adminLogin = '/admin-login';
  static const String onboarding = '/onboarding';
  static const String guestHome = '/guest';

  // --- タブ（ShellRoute 内） ---
  static const String jobList = '/jobs';
  static const String work = '/work';
  static const String messages = '/messages';
  static const String sales = '/sales';
  static const String profile = '/profile';

  // --- 案件系 ---
  static const String jobDetail = '/jobs/:jobId';
  static const String jobEdit = '/jobs/:jobId/edit';
  static const String postJob = '/jobs/new';

  // --- 応募・作業系 ---
  static const String workDetail = '/work/:applicationId';
  static const String chatRoom = '/chat/:applicationId';
  static const String qrCheckin = '/work/:applicationId/qr-checkin';
  static const String shiftQr = '/work/:jobId/shift-qr';

  // --- プロフィール・設定 ---
  static const String myProfile = '/my-profile';
  static const String accountSettings = '/account-settings';
  static const String identityVerification = '/identity-verification';
  static const String stripeOnboarding = '/stripe-onboarding';

  // --- 通知 ---
  static const String notifications = '/notifications';

  // --- 売上 ---
  static const String earningsCreate = '/earnings/new';
  static const String paymentDetail = '/payments/:paymentId';

  // --- その他 ---
  static const String contact = '/contact';
  static const String faq = '/faq';
  static const String legal = '/legal';

  // --- マップ ---
  static const String mapSearch = '/map-search';

  // --- お気に入り ---
  static const String favorites = '/favorites';

  // --- 紹介 ---
  static const String referral = '/referral';

  // --- 電話認証 ---
  static const String phoneAuth = '/phone-auth';

  // --- 日報・検査・タイムライン ---
  static const String workReportCreate = '/work/:applicationId/report/new';
  static const String workInspection = '/work/:applicationId/inspection';
  static const String workTimeline = '/work/:applicationId/timeline';

  // --- 資格 ---
  static const String qualifications = '/qualifications';
  static const String qualificationAdd = '/qualifications/new';

  // --- 明細 ---
  static const String statements = '/statements';
  static const String statementDetail = '/statements/:statementId';

  // --- 法的情報 ---
  static const String legalIndex = '/legal-index';

  // --- 管理者 ---
  static const String adminHome = '/admin';
  static const String adminQualifications = '/admin/qualifications';
  static const String adminEarlyPayments = '/admin/early-payments';
  static const String adminIdentityVerification = '/admin/identity-verification';

  /// パスパラメータを展開するヘルパー
  static String jobDetailPath(String jobId) => '/jobs/$jobId';
  static String jobEditPath(String jobId) => '/jobs/$jobId/edit';
  static String workDetailPath(String applicationId) => '/work/$applicationId';
  static String chatRoomPath(String applicationId) => '/chat/$applicationId';
  static String qrCheckinPath(String applicationId) => '/work/$applicationId/qr-checkin';
  static String shiftQrPath(String jobId) => '/work/$jobId/shift-qr';
  static String paymentDetailPath(String paymentId) => '/payments/$paymentId';
  static String workReportCreatePath(String applicationId) => '/work/$applicationId/report/new';
  static String workInspectionPath(String applicationId) => '/work/$applicationId/inspection';
  static String workTimelinePath(String applicationId) => '/work/$applicationId/timeline';
  static String statementDetailPath(String statementId) => '/statements/$statementId';
}
