/// アプリ全体で使用する定数
class AppConstants {
  // ===== Firebase コレクション名 =====
  static const String collectionJobs = 'jobs';
  static const String collectionApplications = 'applications';
  static const String collectionChats = 'chats';
  static const String collectionProfiles = 'profiles';
  static const String collectionConfig = 'config';

  // ===== 管理者設定 =====
  /// 管理者UID（MVP用の固定値）
  static const String adminUid = '5AeMBYb9PifYVUWMf4lSdCjuM1s1';

  /// 管理者メールアドレスリストを格納するドキュメントパス
  static const String adminConfigPath = 'config/admins';

  // ===== リスト制限 =====
  /// 一覧取得時のデフォルト件数
  static const int defaultListLimit = 50;

  /// 未読数表示の最大値
  static const int maxUnreadDisplay = 99;

  // ===== 都道府県 =====
  static const List<String> prefectures = [
    '千葉県',
    '東京都',
    '神奈川県',
    'その他',
  ];

  /// 「その他」に含まれない都道府県
  static const Set<String> excludedPrefectures = {
    '千葉県',
    '東京都',
    '神奈川県',
  };

  // ===== UI設定 =====
  /// タップ領域の最小サイズ（アクセシビリティ考慮）
  static const double minTapSize = 44.0;

  /// デフォルトのパディング
  static const double defaultPadding = 16.0;

  /// ボーダー半径
  static const double defaultBorderRadius = 12.0;

  // ===== アプリ情報 =====
  static const String appName = 'ALBAWORK';
  static const String appVersion = '1.0.0';
}
