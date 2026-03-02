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

  // === Input Validation Limits (Firestore rules と一致) ===
  static const int maxMessageLength = 5000;
  static const int maxJobTitleLength = 100;
  static const int maxJobLocationLength = 200;
  static const int maxJobDescriptionLength = 5000;
  static const int maxJobNotesLength = 2000;
  static const int maxDisplayNameLength = 50;
  static const int maxIntroductionLength = 2000;
  static const int maxExperienceYearsLength = 3;
  static const int maxAddressLength = 200;
  static const int maxQualificationLength = 50;
  static const int maxContactSubjectLength = 200;
  static const int maxContactBodyLength = 5000;
  static const String postalCodePattern = r'^\d{3}-?\d{4}$';

  // === Performance ===
  static const double listCacheExtent = 500.0;
  static const int firestoreCacheSizeBytes = 100 * 1024 * 1024; // 100MB
}
