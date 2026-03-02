import 'package:cloud_firestore/cloud_firestore.dart';

/// 資格（Qualification）のデータモデル（構造化版 v2）
class QualificationModel {
  final String id;
  final String uid;
  final String name; // 資格名（max 100文字）
  final String category; // カテゴリキー
  final String? certPhotoUrl; // 証明書写真URL
  final String? expiryDate; // YYYY-MM-DD（null=無期限）
  final String verificationStatus; // 'pending' | 'approved' | 'rejected'
  final String? reviewedBy;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QualificationModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.category,
    this.certPhotoUrl,
    this.expiryDate,
    this.verificationStatus = 'pending',
    this.reviewedBy,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  bool get isVerified => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';

  bool get isExpired {
    if (expiryDate == null) return false;
    final expiry = DateTime.tryParse(expiryDate!);
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now());
  }

  factory QualificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return QualificationModel.fromMap(doc.id, data);
  }

  factory QualificationModel.fromMap(String id, Map<String, dynamic> data) {
    return QualificationModel(
      id: id,
      uid: data['uid']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? 'other',
      certPhotoUrl: data['certPhotoUrl']?.toString(),
      expiryDate: data['expiryDate']?.toString(),
      verificationStatus:
          data['verificationStatus']?.toString() ?? 'pending',
      reviewedBy: data['reviewedBy']?.toString(),
      rejectionReason: data['rejectionReason']?.toString(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'category': category,
      if (certPhotoUrl != null) 'certPhotoUrl': certPhotoUrl,
      if (expiryDate != null) 'expiryDate': expiryDate,
      'verificationStatus': verificationStatus,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
      ...toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  QualificationModel copyWith({
    String? id,
    String? uid,
    String? name,
    String? category,
    String? certPhotoUrl,
    String? expiryDate,
    String? verificationStatus,
    String? reviewedBy,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QualificationModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      category: category ?? this.category,
      certPhotoUrl: certPhotoUrl ?? this.certPhotoUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QualificationModel &&
          other.id == id &&
          other.uid == uid &&
          other.name == name &&
          other.category == category &&
          other.certPhotoUrl == certPhotoUrl &&
          other.expiryDate == expiryDate &&
          other.verificationStatus == verificationStatus &&
          other.reviewedBy == reviewedBy &&
          other.rejectionReason == rejectionReason &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(
        id,
        uid,
        name,
        category,
        certPhotoUrl,
        expiryDate,
        verificationStatus,
        reviewedBy,
        rejectionReason,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'QualificationModel(id: $id, name: $name, status: $verificationStatus)';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
