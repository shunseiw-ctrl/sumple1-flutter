class AppConstants {
  static const String collectionJobs = 'jobs';
  static const String collectionApplications = 'applications';
  static const String collectionChats = 'chats';
  static const String collectionProfiles = 'profiles';
  static const String collectionConfig = 'config';

  static const String adminConfigPath = 'config/admins';

  static const int defaultListLimit = 50;

  static const int maxUnreadDisplay = 99;

  static const List<String> prefectures = [
    '千葉県',
    '東京都',
    '神奈川県',
    'その他',
  ];

  static const Set<String> excludedPrefectures = {
    '千葉県',
    '東京都',
    '神奈川県',
  };

  static const double minTapSize = 44.0;

  static const double defaultPadding = 16.0;

  static const double defaultBorderRadius = 12.0;

  static const String appName = 'ALBAWORK';
  static const String appVersion = '1.0.0';
}
