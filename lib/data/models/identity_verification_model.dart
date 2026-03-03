import 'package:cloud_firestore/cloud_firestore.dart';

class IdentityVerificationModel {
  final String uid;
  final String idPhotoUrl;
  final String selfieUrl;
  final String documentType;
  final String status;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const IdentityVerificationModel({
    required this.uid,
    required this.idPhotoUrl,
    required this.selfieUrl,
    this.documentType = 'drivers_license',
    this.status = 'pending',
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  factory IdentityVerificationModel.fromMap(Map<String, dynamic> map) {
    return IdentityVerificationModel(
      uid: (map['uid'] ?? '').toString(),
      idPhotoUrl: (map['idPhotoUrl'] ?? '').toString(),
      selfieUrl: (map['selfieUrl'] ?? '').toString(),
      documentType: (map['documentType'] ?? 'drivers_license').toString(),
      status: (map['status'] ?? 'pending').toString(),
      submittedAt: map['submittedAt'] is Timestamp
          ? (map['submittedAt'] as Timestamp).toDate()
          : map['submittedAt'] is DateTime
              ? map['submittedAt'] as DateTime
              : null,
      reviewedBy: map['reviewedBy']?.toString(),
      reviewedAt: map['reviewedAt'] is Timestamp
          ? (map['reviewedAt'] as Timestamp).toDate()
          : map['reviewedAt'] is DateTime
              ? map['reviewedAt'] as DateTime
              : null,
      rejectionReason: map['rejectionReason']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'idPhotoUrl': idPhotoUrl,
      'selfieUrl': selfieUrl,
      'documentType': documentType,
      'status': status,
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  IdentityVerificationModel copyWith({
    String? uid,
    String? idPhotoUrl,
    String? selfieUrl,
    String? documentType,
    String? status,
    DateTime? submittedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return IdentityVerificationModel(
      uid: uid ?? this.uid,
      idPhotoUrl: idPhotoUrl ?? this.idPhotoUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      documentType: documentType ?? this.documentType,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityVerificationModel &&
          uid == other.uid &&
          idPhotoUrl == other.idPhotoUrl &&
          selfieUrl == other.selfieUrl &&
          documentType == other.documentType &&
          status == other.status &&
          reviewedBy == other.reviewedBy &&
          rejectionReason == other.rejectionReason;

  @override
  int get hashCode => Object.hash(uid, idPhotoUrl, selfieUrl, documentType, status, reviewedBy, rejectionReason);

  static const documentTypes = {
    'drivers_license': '運転免許証',
    'my_number': 'マイナンバーカード',
    'passport': 'パスポート',
    'residence_card': '在留カード',
  };

  String get documentTypeLabel => documentTypes[documentType] ?? documentType;
}
