import 'package:share_plus/share_plus.dart';

/// シェア機能のユーティリティクラス
class ShareService {
  // --- テキスト生成（テスト用に公開） ---

  static String shareJobText(String jobId, String title, String price, String location) {
    return '【ALBAWORK】$title\n場所: $location\n日給: $price円\nhttps://albawork.app/jobs/$jobId';
  }

  static String shareReferralText(String code) {
    return 'ALBAWORKで一緒に働こう！紹介コード: $code\nhttps://albawork.app';
  }

  static String shareAppText() {
    return 'ALBAWORKで建設業の仕事を見つけよう！\nhttps://albawork.app';
  }

  // --- シェア実行 ---

  static Future<void> shareJob(String jobId, String title, String price, String location) async {
    await Share.share(shareJobText(jobId, title, price, location));
  }

  static Future<void> shareReferral(String code) async {
    await Share.share(shareReferralText(code));
  }

  static Future<void> shareApp() async {
    await Share.share(shareAppText());
  }
}
