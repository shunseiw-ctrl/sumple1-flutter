import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// テスト用の共通ヘルパー
class TestHelpers {
  /// テスト用のFirestoreインスタンスを作成
  static FakeFirebaseFirestore createFakeFirestore() {
    return FakeFirebaseFirestore();
  }

  /// テスト用の管理者設定をFirestoreにセットアップ
  static Future<void> setupAdminConfig(
    FakeFirebaseFirestore firestore, {
    List<String> adminUids = const [],
    List<String> emails = const [],
  }) async {
    await firestore.doc('config/admins').set({
      'adminUids': adminUids,
      'emails': emails,
    });
  }

  /// テスト用の求人データを作成
  static Map<String, dynamic> createJobData({
    String title = 'テスト案件',
    String location = '東京都新宿区',
    String prefecture = '東京都',
    int price = 30000,
    String date = '2026-03-01',
    String? ownerId,
  }) {
    return {
      'title': title,
      'location': location,
      'prefecture': prefecture,
      'price': price,
      'date': date,
      'workMonthKey': '2026-03',
      'workDateKey': date,
      'ownerId': ownerId ?? 'test-owner-uid',
      'description': '',
      'notes': '',
    };
  }

  /// テスト用の応募データを作成
  static Map<String, dynamic> createApplicationData({
    String applicantUid = 'applicant-uid',
    String adminUid = 'admin-uid',
    String jobId = 'job-1',
    String status = 'applied',
    String projectNameSnapshot = 'テスト案件',
  }) {
    return {
      'applicantUid': applicantUid,
      'adminUid': adminUid,
      'jobId': jobId,
      'status': status,
      'projectNameSnapshot': projectNameSnapshot,
    };
  }
}
