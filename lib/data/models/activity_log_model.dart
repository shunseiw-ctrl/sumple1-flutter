import 'package:cloud_firestore/cloud_firestore.dart';

/// 工程タイムライン用の活動ログモデル
class ActivityLogModel {
  final String id;
  final String applicationId;
  final String actorUid;
  final String actorRole; // 'worker' | 'admin'
  final String eventType; // 'status_change' | 'checkin' | 'checkout' | 'report_submitted' | 'inspection_completed' | 'note_added'
  final String description; // 人間が読める説明（max 500文字）
  final Map<String, dynamic>? metadata; // イベント固有データ
  final DateTime? createdAt;

  ActivityLogModel({
    required this.id,
    required this.applicationId,
    required this.actorUid,
    required this.actorRole,
    required this.eventType,
    required this.description,
    this.metadata,
    this.createdAt,
  });

  factory ActivityLogModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return ActivityLogModel.fromMap(doc.id, data);
  }

  factory ActivityLogModel.fromMap(String id, Map<String, dynamic> data) {
    return ActivityLogModel(
      id: id,
      applicationId: data['applicationId']?.toString() ?? '',
      actorUid: data['actorUid']?.toString() ?? '',
      actorRole: data['actorRole']?.toString() ?? 'worker',
      eventType: data['eventType']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      metadata: data['metadata'] is Map<String, dynamic>
          ? data['metadata'] as Map<String, dynamic>
          : null,
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'actorUid': actorUid,
      'actorRole': actorRole,
      'eventType': eventType,
      'description': description,
      if (metadata != null) 'metadata': metadata,
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      ...toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityLogModel &&
          other.id == id &&
          other.applicationId == applicationId &&
          other.actorUid == actorUid &&
          other.actorRole == actorRole &&
          other.eventType == eventType &&
          other.description == description &&
          other.createdAt == createdAt);

  @override
  int get hashCode => Object.hash(
        id,
        applicationId,
        actorUid,
        actorRole,
        eventType,
        description,
        createdAt,
      );

  @override
  String toString() {
    return 'ActivityLogModel(id: $id, eventType: $eventType, description: $description)';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
