/// ユーザーの役割を定義
enum UserRole {
  /// 未認証・未登録ユーザー
  guest,

  /// 一般ユーザー（職人）
  user,

  /// 管理者（案件投稿者）
  admin,
}

extension UserRoleExtension on UserRole {
  /// ロールの表示名
  String get displayName {
    switch (this) {
      case UserRole.guest:
        return 'ゲスト';
      case UserRole.user:
        return '一般ユーザー';
      case UserRole.admin:
        return '管理者';
    }
  }

  /// 管理者かどうか
  bool get isAdmin => this == UserRole.admin;

  /// 認証済みかどうか
  bool get isAuthenticated => this != UserRole.guest;

  /// ゲストかどうか
  bool get isGuest => this == UserRole.guest;
}
