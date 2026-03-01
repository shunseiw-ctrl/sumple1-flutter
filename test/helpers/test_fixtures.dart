/// テスト用フィクスチャデータ
class TestFixtures {
  TestFixtures._();

  /// 案件テストデータ
  static Map<String, dynamic> jobData({
    String? title,
    String? location,
    String? prefecture,
    int? price,
    String? ownerId,
  }) {
    return {
      'title': title ?? '内装工事',
      'location': location ?? '東京都新宿区',
      'prefecture': prefecture ?? '東京都',
      'price': price ?? 15000,
      'date': '2025-04-01',
      'workMonthKey': '2025-04',
      'ownerId': ownerId ?? 'admin-001',
      'description': 'テスト案件の説明',
      'latitude': 35.6895,
      'longitude': 139.6917,
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// 応募テストデータ
  static Map<String, dynamic> applicationData({
    String? applicantUid,
    String? adminUid,
    String? jobId,
    String? status,
    String? projectNameSnapshot,
    String? jobTitleSnapshot,
    String? titleSnapshot,
  }) {
    return {
      'applicantUid': applicantUid ?? 'worker-001',
      'adminUid': adminUid ?? 'admin-001',
      'jobId': jobId ?? 'job-001',
      'status': status ?? 'applied',
      if (projectNameSnapshot != null)
        'projectNameSnapshot': projectNameSnapshot,
      if (jobTitleSnapshot != null) 'jobTitleSnapshot': jobTitleSnapshot,
      if (titleSnapshot != null) 'titleSnapshot': titleSnapshot,
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// チャットテストデータ
  static Map<String, dynamic> chatData({
    String? applicationId,
    String? applicantUid,
    String? adminUid,
    String? jobId,
    String? titleSnapshot,
    String? lastMessageText,
    String? lastMessageSenderUid,
    int? unreadCountApplicant,
    int? unreadCountAdmin,
  }) {
    return {
      'applicationId': applicationId ?? 'app-001',
      'applicantUid': applicantUid ?? 'worker-001',
      'adminUid': adminUid ?? 'admin-001',
      'jobId': jobId ?? 'job-001',
      'titleSnapshot': titleSnapshot ?? '内装工事案件',
      if (lastMessageText != null) 'lastMessageText': lastMessageText,
      if (lastMessageSenderUid != null)
        'lastMessageSenderUid': lastMessageSenderUid,
      'unreadCountApplicant': unreadCountApplicant ?? 0,
      'unreadCountAdmin': unreadCountAdmin ?? 0,
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// メッセージテストデータ
  static Map<String, dynamic> messageData({
    String? senderUid,
    String? text,
  }) {
    return {
      'senderUid': senderUid ?? 'worker-001',
      'text': text ?? 'テストメッセージです',
      'createdAt': DateTime(2025, 1, 1),
    };
  }

  /// シフトテストデータ
  static Map<String, dynamic> shiftData({
    String? date,
    String? qrCode,
    String? createdBy,
  }) {
    return {
      'date': date ?? '2025-04-01',
      'qrCode': qrCode ?? 'shift-abc123',
      'createdBy': createdBy ?? 'admin-001',
      'createdAt': DateTime(2025, 1, 1),
    };
  }

  /// 決済テストデータ
  static Map<String, dynamic> paymentData({
    String? applicationId,
    String? jobId,
    String? workerUid,
    String? adminUid,
    int? amount,
    int? platformFee,
    int? netAmount,
    String? status,
    String? payoutStatus,
    String? projectNameSnapshot,
  }) {
    return {
      'applicationId': applicationId ?? 'app-001',
      'jobId': jobId ?? 'job-001',
      'workerUid': workerUid ?? 'worker-001',
      'adminUid': adminUid ?? 'admin-001',
      'amount': amount ?? 15000,
      'platformFee': platformFee ?? 1500,
      'netAmount': netAmount ?? 13500,
      'stripePaymentIntentId': 'pi_test_123',
      'status': status ?? 'pending',
      'payoutStatus': payoutStatus ?? 'pending',
      'projectNameSnapshot': projectNameSnapshot ?? '内装工事案件',
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// QRコード文字列生成
  static String validQrData({
    String jobId = 'job-001',
    String shiftCode = 'shift-abc123',
  }) {
    return 'albawork://checkin/$jobId/$shiftCode';
  }
}
