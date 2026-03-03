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

  /// 画像メッセージテストデータ
  static Map<String, dynamic> imageMessageData({
    String? senderUid,
    String? text,
    String? imageUrl,
  }) {
    return {
      'senderUid': senderUid ?? 'worker-001',
      'text': text ?? '',
      'imageUrl': imageUrl ?? 'https://example.com/test-image.jpg',
      'messageType': 'image',
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

  /// 日報テストデータ
  static Map<String, dynamic> workReportData({
    String? applicationId,
    String? workerUid,
    String? reportDate,
    String? workContent,
    double? hoursWorked,
    List<String>? photoUrls,
    String? notes,
  }) {
    return {
      'applicationId': applicationId ?? 'app-001',
      'workerUid': workerUid ?? 'worker-001',
      'reportDate': reportDate ?? '2025-04-01',
      'workContent': workContent ?? '内装工事の作業を行いました',
      'hoursWorked': hoursWorked ?? 8.0,
      'photoUrls': photoUrls ?? [],
      if (notes != null) 'notes': notes,
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// 活動ログテストデータ
  static Map<String, dynamic> activityLogData({
    String? applicationId,
    String? actorUid,
    String? actorRole,
    String? eventType,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'applicationId': applicationId ?? 'app-001',
      'actorUid': actorUid ?? 'worker-001',
      'actorRole': actorRole ?? 'worker',
      'eventType': eventType ?? 'status_change',
      'description': description ?? 'ステータスが変更されました',
      if (metadata != null) 'metadata': metadata,
      'createdAt': DateTime(2025, 1, 1),
    };
  }

  /// 検査テストデータ
  static Map<String, dynamic> inspectionData({
    String? applicationId,
    String? inspectorUid,
    String? result,
    List<Map<String, dynamic>>? items,
    String? overallComment,
  }) {
    return {
      'applicationId': applicationId ?? 'app-001',
      'inspectorUid': inspectorUid ?? 'admin-001',
      'result': result ?? 'passed',
      'items': items ??
          [
            {'label': '仕上がり品質', 'result': 'pass'},
            {'label': '清掃状況', 'result': 'pass'},
          ],
      'photoUrls': <String>[],
      if (overallComment != null) 'overallComment': overallComment,
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// 検査チェック項目テストデータ
  static Map<String, dynamic> inspectionCheckItemData({
    String? label,
    String? result,
    String? comment,
  }) {
    return {
      'label': label ?? '仕上がり品質',
      'result': result ?? 'pass',
      if (comment != null) 'comment': comment,
    };
  }

  /// 資格テストデータ
  static Map<String, dynamic> qualificationData({
    String? uid,
    String? name,
    String? category,
    String? certPhotoUrl,
    String? expiryDate,
    String? verificationStatus,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return {
      'uid': uid ?? 'worker-001',
      'name': name ?? '内装仕上げ施工技能士',
      'category': category ?? 'interior',
      if (certPhotoUrl != null) 'certPhotoUrl': certPhotoUrl,
      if (expiryDate != null) 'expiryDate': expiryDate,
      'verificationStatus': verificationStatus ?? 'pending',
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// 月次明細テストデータ
  static Map<String, dynamic> monthlyStatementData({
    String? workerUid,
    String? month,
    List<Map<String, dynamic>>? items,
    int? totalAmount,
    int? netAmount,
    String? status,
    String? paymentDate,
    bool? earlyPaymentRequested,
  }) {
    return {
      'workerUid': workerUid ?? 'worker-001',
      'month': month ?? '2025-04',
      'items': items ??
          [
            {
              'applicationId': 'app-001',
              'jobTitle': '内装工事',
              'completedDate': '2025-04-15',
              'amount': 150000,
            },
          ],
      'totalAmount': totalAmount ?? 150000,
      'netAmount': netAmount ?? 150000,
      'status': status ?? 'draft',
      if (paymentDate != null) 'paymentDate': paymentDate,
      'earlyPaymentRequested': earlyPaymentRequested ?? false,
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// 即金申請テストデータ
  static Map<String, dynamic> earlyPaymentRequestData({
    String? workerUid,
    String? statementId,
    String? month,
    int? requestedAmount,
    int? earlyPaymentFee,
    int? payoutAmount,
    String? status,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return {
      'workerUid': workerUid ?? 'worker-001',
      'statementId': statementId ?? 'stmt-001',
      'month': month ?? '2025-04',
      'requestedAmount': requestedAmount ?? 150000,
      'earlyPaymentFee': earlyPaymentFee ?? 15000,
      'payoutAmount': payoutAmount ?? 135000,
      'status': status ?? 'requested',
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
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

  /// 本人確認テストデータ
  static Map<String, dynamic> identityVerificationData({
    String? uid,
    String? idPhotoUrl,
    String? selfieUrl,
    String? documentType,
    String? status,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return {
      'uid': uid ?? 'worker-001',
      'idPhotoUrl': idPhotoUrl ?? 'https://example.com/id.jpg',
      'selfieUrl': selfieUrl ?? 'https://example.com/selfie.jpg',
      'documentType': documentType ?? 'drivers_license',
      'status': status ?? 'pending',
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'submittedAt': DateTime(2025, 1, 1),
      'createdAt': DateTime(2025, 1, 1),
    };
  }

  /// 管理者プロフィールテストデータ
  static Map<String, dynamic> adminProfileData({
    String? uid,
    String? displayName,
    String? email,
  }) {
    return {
      'uid': uid ?? 'admin-001',
      'displayName': displayName ?? '管理者テスト',
      'email': email ?? 'admin@albawork.com',
      'role': 'admin',
      'createdAt': DateTime(2025, 1, 1),
      'updatedAt': DateTime(2025, 1, 1),
    };
  }

  /// 決済テスト結果データ
  static Map<String, dynamic> paymentTestResultData({
    bool? allPassed,
    int? passedCount,
    int? failedCount,
  }) {
    return {
      'allPassed': allPassed ?? true,
      'passedCount': passedCount ?? 2,
      'failedCount': failedCount ?? 0,
      'testedAt': DateTime(2025, 1, 1),
    };
  }
}
