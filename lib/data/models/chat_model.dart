import 'package:cloud_firestore/cloud_firestore.dart';

/// チャット（Chat）のデータモデル
class ChatModel {
  final String id;
  final String applicationId;
  final String applicantUid;
  final String adminUid;
  final String jobId;
  final String titleSnapshot;
  final String? lastMessageText;
  final String? lastMessageSenderUid;
  final DateTime? lastMessageAt;
  final int unreadCountApplicant;
  final int unreadCountAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatModel({
    required this.id,
    required this.applicationId,
    required this.applicantUid,
    required this.adminUid,
    required this.jobId,
    required this.titleSnapshot,
    this.lastMessageText,
    this.lastMessageSenderUid,
    this.lastMessageAt,
    this.unreadCountApplicant = 0,
    this.unreadCountAdmin = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Firestoreドキュメントからモデルを生成
  factory ChatModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    return ChatModel(
      id: doc.id,
      applicationId: data['applicationId']?.toString() ?? '',
      applicantUid: data['applicantUid']?.toString() ?? '',
      adminUid: data['adminUid']?.toString() ?? '',
      jobId: data['jobId']?.toString() ?? '',
      titleSnapshot: data['titleSnapshot']?.toString() ?? 'チャット',
      lastMessageText: data['lastMessageText']?.toString(),
      lastMessageSenderUid: data['lastMessageSenderUid']?.toString(),
      lastMessageAt: _toDateTime(data['lastMessageAt']),
      unreadCountApplicant: _toInt(data['unreadCountApplicant']) ?? 0,
      unreadCountAdmin: _toInt(data['unreadCountAdmin']) ?? 0,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  /// Mapからモデルを生成
  factory ChatModel.fromMap(String id, Map<String, dynamic> data) {
    return ChatModel(
      id: id,
      applicationId: data['applicationId']?.toString() ?? '',
      applicantUid: data['applicantUid']?.toString() ?? '',
      adminUid: data['adminUid']?.toString() ?? '',
      jobId: data['jobId']?.toString() ?? '',
      titleSnapshot: data['titleSnapshot']?.toString() ?? 'チャット',
      lastMessageText: data['lastMessageText']?.toString(),
      lastMessageSenderUid: data['lastMessageSenderUid']?.toString(),
      lastMessageAt: _toDateTime(data['lastMessageAt']),
      unreadCountApplicant: _toInt(data['unreadCountApplicant']) ?? 0,
      unreadCountAdmin: _toInt(data['unreadCountAdmin']) ?? 0,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  /// Firestoreに保存する形式に変換（更新用）
  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'applicantUid': applicantUid,
      'adminUid': adminUid,
      'jobId': jobId,
      'titleSnapshot': titleSnapshot,
      if (lastMessageText != null) 'lastMessageText': lastMessageText,
      if (lastMessageSenderUid != null) 'lastMessageSenderUid': lastMessageSenderUid,
      if (lastMessageAt != null) 'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
      'unreadCountApplicant': unreadCountApplicant,
      'unreadCountAdmin': unreadCountAdmin,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// 新規作成用のMap（7キー固定）
  Map<String, dynamic> toCreateMap() {
    return {
      'applicationId': applicationId,
      'applicantUid': applicantUid,
      'adminUid': adminUid,
      'jobId': jobId,
      'titleSnapshot': titleSnapshot,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// 指定されたユーザーの未読数を取得
  int getUnreadCount(String userId) {
    if (userId == applicantUid) {
      return unreadCountApplicant;
    } else if (userId == adminUid) {
      return unreadCountAdmin;
    }
    return 0;
  }

  /// 指定されたユーザーが応募者か
  bool isApplicant(String userId) {
    return applicantUid == userId;
  }

  /// 指定されたユーザーが管理者か
  bool isAdmin(String userId) {
    return adminUid == userId;
  }

  /// 指定されたユーザーが当事者か
  bool isParticipant(String userId) {
    return isApplicant(userId) || isAdmin(userId);
  }

  /// 最後のメッセージがあるか
  bool get hasLastMessage => lastMessageText != null && lastMessageText!.isNotEmpty;

  /// コピーを作成
  ChatModel copyWith({
    String? id,
    String? applicationId,
    String? applicantUid,
    String? adminUid,
    String? jobId,
    String? titleSnapshot,
    String? lastMessageText,
    String? lastMessageSenderUid,
    DateTime? lastMessageAt,
    int? unreadCountApplicant,
    int? unreadCountAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      applicantUid: applicantUid ?? this.applicantUid,
      adminUid: adminUid ?? this.adminUid,
      jobId: jobId ?? this.jobId,
      titleSnapshot: titleSnapshot ?? this.titleSnapshot,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderUid: lastMessageSenderUid ?? this.lastMessageSenderUid,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCountApplicant: unreadCountApplicant ?? this.unreadCountApplicant,
      unreadCountAdmin: unreadCountAdmin ?? this.unreadCountAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChatModel(id: $id, title: $titleSnapshot, lastMessage: $lastMessageText)';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
