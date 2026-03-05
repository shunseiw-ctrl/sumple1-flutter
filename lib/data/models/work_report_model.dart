import 'package:cloud_firestore/cloud_firestore.dart';

/// 日報（WorkReport）のデータモデル
class WorkReportModel {
  final String id;
  final String applicationId;
  final String workerUid;
  final String reportDate; // YYYY-MM-DD
  final String workContent; // 作業内容（max 2000文字）
  final double hoursWorked; // 作業時間（例: 8.0）
  final List<String> photoUrls; // 現場写真（最大10枚）
  final String? notes; // 備考（max 1000文字）
  final String reviewStatus; // 'pending' | 'reviewed'
  final String? adminComment; // 管理者コメント（max 2000文字）
  final String? reviewedBy; // レビュー管理者UID
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkReportModel({
    required this.id,
    required this.applicationId,
    required this.workerUid,
    required this.reportDate,
    required this.workContent,
    required this.hoursWorked,
    this.photoUrls = const [],
    this.notes,
    this.reviewStatus = 'pending',
    this.adminComment,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isReviewed => reviewStatus == 'reviewed';
  bool get isPending => reviewStatus == 'pending';

  factory WorkReportModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return WorkReportModel.fromMap(doc.id, data);
  }

  factory WorkReportModel.fromMap(String id, Map<String, dynamic> data) {
    return WorkReportModel(
      id: id,
      applicationId: data['applicationId']?.toString() ?? '',
      workerUid: data['workerUid']?.toString() ?? '',
      reportDate: data['reportDate']?.toString() ?? '',
      workContent: data['workContent']?.toString() ?? '',
      hoursWorked: _parseDouble(data['hoursWorked']) ?? 0.0,
      photoUrls: _parseStringList(data['photoUrls']),
      notes: data['notes']?.toString(),
      reviewStatus: data['reviewStatus']?.toString() ?? 'pending',
      adminComment: data['adminComment']?.toString(),
      reviewedBy: data['reviewedBy']?.toString(),
      reviewedAt: _toDateTime(data['reviewedAt']),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'workerUid': workerUid,
      'reportDate': reportDate,
      'workContent': workContent,
      'hoursWorked': hoursWorked,
      'photoUrls': photoUrls,
      if (notes != null) 'notes': notes,
      'reviewStatus': reviewStatus,
      if (adminComment != null) 'adminComment': adminComment,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      ...toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  WorkReportModel copyWith({
    String? id,
    String? applicationId,
    String? workerUid,
    String? reportDate,
    String? workContent,
    double? hoursWorked,
    List<String>? photoUrls,
    String? notes,
    String? reviewStatus,
    String? adminComment,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkReportModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      workerUid: workerUid ?? this.workerUid,
      reportDate: reportDate ?? this.reportDate,
      workContent: workContent ?? this.workContent,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      photoUrls: photoUrls ?? this.photoUrls,
      notes: notes ?? this.notes,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      adminComment: adminComment ?? this.adminComment,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkReportModel &&
          other.id == id &&
          other.applicationId == applicationId &&
          other.workerUid == workerUid &&
          other.reportDate == reportDate &&
          other.workContent == workContent &&
          other.hoursWorked == hoursWorked &&
          _listEquals(other.photoUrls, photoUrls) &&
          other.notes == notes &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(
        id,
        applicationId,
        workerUid,
        reportDate,
        workContent,
        hoursWorked,
        Object.hashAll(photoUrls),
        notes,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'WorkReportModel(id: $id, reportDate: $reportDate, hoursWorked: $hoursWorked)';
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
