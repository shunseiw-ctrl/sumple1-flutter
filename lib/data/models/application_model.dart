import 'package:cloud_firestore/cloud_firestore.dart';

/// 応募（Application）のデータモデル
class ApplicationModel {
  final String id;
  final String applicantUid;
  final String adminUid;
  final String jobId;
  final String status;
  final String? projectNameSnapshot;
  final String? jobTitleSnapshot;
  final String? titleSnapshot;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ApplicationModel({
    required this.id,
    required this.applicantUid,
    required this.adminUid,
    required this.jobId,
    required this.status,
    this.projectNameSnapshot,
    this.jobTitleSnapshot,
    this.titleSnapshot,
    this.createdAt,
    this.updatedAt,
  });

  /// Firestoreドキュメントからモデルを生成
  factory ApplicationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    return ApplicationModel(
      id: doc.id,
      applicantUid: data['applicantUid']?.toString() ?? '',
      adminUid: data['adminUid']?.toString() ?? '',
      jobId: data['jobId']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      projectNameSnapshot: data['projectNameSnapshot']?.toString(),
      jobTitleSnapshot: data['jobTitleSnapshot']?.toString(),
      titleSnapshot: data['titleSnapshot']?.toString(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  /// Mapからモデルを生成
  factory ApplicationModel.fromMap(String id, Map<String, dynamic> data) {
    return ApplicationModel(
      id: id,
      applicantUid: data['applicantUid']?.toString() ?? '',
      adminUid: data['adminUid']?.toString() ?? '',
      jobId: data['jobId']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      projectNameSnapshot: data['projectNameSnapshot']?.toString(),
      jobTitleSnapshot: data['jobTitleSnapshot']?.toString(),
      titleSnapshot: data['titleSnapshot']?.toString(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  /// Firestoreに保存する形式に変換
  Map<String, dynamic> toMap() {
    return {
      'applicantUid': applicantUid,
      'adminUid': adminUid,
      'jobId': jobId,
      'status': status,
      if (projectNameSnapshot != null) 'projectNameSnapshot': projectNameSnapshot,
      if (jobTitleSnapshot != null) 'jobTitleSnapshot': jobTitleSnapshot,
      if (titleSnapshot != null) 'titleSnapshot': titleSnapshot,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// 新規作成用のMap
  Map<String, dynamic> toCreateMap() {
    return {
      ...toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// 表示用のタイトルを取得（優先度: projectName > jobTitle > title > デフォルト）
  String get displayTitle {
    return projectNameSnapshot ??
        jobTitleSnapshot ??
        titleSnapshot ??
        '案件';
  }

  /// 指定されたユーザーが応募者か
  bool isApplicant(String userId) {
    return applicantUid == userId;
  }

  /// 指定されたユーザーが管理者か
  bool isAdmin(String userId) {
    return adminUid == userId;
  }

  /// 指定されたユーザーが当事者（応募者または管理者）か
  bool isParticipant(String userId) {
    return isApplicant(userId) || isAdmin(userId);
  }

  /// コピーを作成
  ApplicationModel copyWith({
    String? id,
    String? applicantUid,
    String? adminUid,
    String? jobId,
    String? status,
    String? projectNameSnapshot,
    String? jobTitleSnapshot,
    String? titleSnapshot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      applicantUid: applicantUid ?? this.applicantUid,
      adminUid: adminUid ?? this.adminUid,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      projectNameSnapshot: projectNameSnapshot ?? this.projectNameSnapshot,
      jobTitleSnapshot: jobTitleSnapshot ?? this.jobTitleSnapshot,
      titleSnapshot: titleSnapshot ?? this.titleSnapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApplicationModel &&
          other.id == id &&
          other.applicantUid == applicantUid &&
          other.adminUid == adminUid &&
          other.jobId == jobId &&
          other.status == status &&
          other.projectNameSnapshot == projectNameSnapshot &&
          other.jobTitleSnapshot == jobTitleSnapshot &&
          other.titleSnapshot == titleSnapshot &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(
        id,
        applicantUid,
        adminUid,
        jobId,
        status,
        projectNameSnapshot,
        jobTitleSnapshot,
        titleSnapshot,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'ApplicationModel(id: $id, title: $displayTitle, status: $status)';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
