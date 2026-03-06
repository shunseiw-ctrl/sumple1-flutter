import 'package:cloud_firestore/cloud_firestore.dart';

class IdentityVerificationModel {
  final String uid;
  final String idPhotoUrl;
  final String? idPhotoBackUrl;
  final String selfieUrl;
  final String documentType;
  final String status;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final double? faceMatchScore;
  final bool livenessVerified;
  final DateTime? livenessCompletedAt;
  final DateTime? faceMatchedAt;

  const IdentityVerificationModel({
    required this.uid,
    required this.idPhotoUrl,
    this.idPhotoBackUrl,
    required this.selfieUrl,
    this.documentType = 'drivers_license',
    this.status = 'pending',
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.faceMatchScore,
    this.livenessVerified = false,
    this.livenessCompletedAt,
    this.faceMatchedAt,
  });

  factory IdentityVerificationModel.fromMap(Map<String, dynamic> map) {
    return IdentityVerificationModel(
      uid: (map['uid'] ?? '').toString(),
      idPhotoUrl: (map['idPhotoUrl'] ?? '').toString(),
      idPhotoBackUrl: map['idPhotoBackUrl']?.toString(),
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
      faceMatchScore: (map['faceMatchScore'] as num?)?.toDouble(),
      livenessVerified: map['livenessVerified'] == true,
      livenessCompletedAt: map['livenessCompletedAt'] is Timestamp
          ? (map['livenessCompletedAt'] as Timestamp).toDate()
          : map['livenessCompletedAt'] is DateTime
              ? map['livenessCompletedAt'] as DateTime
              : null,
      faceMatchedAt: map['faceMatchedAt'] is Timestamp
          ? (map['faceMatchedAt'] as Timestamp).toDate()
          : map['faceMatchedAt'] is DateTime
              ? map['faceMatchedAt'] as DateTime
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'idPhotoUrl': idPhotoUrl,
      if (idPhotoBackUrl != null) 'idPhotoBackUrl': idPhotoBackUrl,
      'selfieUrl': selfieUrl,
      'documentType': documentType,
      'status': status,
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (faceMatchScore != null) 'faceMatchScore': faceMatchScore,
      'livenessVerified': livenessVerified,
      if (livenessCompletedAt != null)
        'livenessCompletedAt': Timestamp.fromDate(livenessCompletedAt!),
      if (faceMatchedAt != null)
        'faceMatchedAt': Timestamp.fromDate(faceMatchedAt!),
    };
  }

  IdentityVerificationModel copyWith({
    String? uid,
    String? idPhotoUrl,
    String? idPhotoBackUrl,
    String? selfieUrl,
    String? documentType,
    String? status,
    DateTime? submittedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    double? faceMatchScore,
    bool? livenessVerified,
    DateTime? livenessCompletedAt,
    DateTime? faceMatchedAt,
  }) {
    return IdentityVerificationModel(
      uid: uid ?? this.uid,
      idPhotoUrl: idPhotoUrl ?? this.idPhotoUrl,
      idPhotoBackUrl: idPhotoBackUrl ?? this.idPhotoBackUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      documentType: documentType ?? this.documentType,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      faceMatchScore: faceMatchScore ?? this.faceMatchScore,
      livenessVerified: livenessVerified ?? this.livenessVerified,
      livenessCompletedAt: livenessCompletedAt ?? this.livenessCompletedAt,
      faceMatchedAt: faceMatchedAt ?? this.faceMatchedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityVerificationModel &&
          uid == other.uid &&
          idPhotoUrl == other.idPhotoUrl &&
          idPhotoBackUrl == other.idPhotoBackUrl &&
          selfieUrl == other.selfieUrl &&
          documentType == other.documentType &&
          status == other.status &&
          reviewedBy == other.reviewedBy &&
          rejectionReason == other.rejectionReason &&
          faceMatchScore == other.faceMatchScore &&
          livenessVerified == other.livenessVerified;

  @override
  int get hashCode => Object.hash(
        uid,
        idPhotoUrl,
        idPhotoBackUrl,
        selfieUrl,
        documentType,
        status,
        reviewedBy,
        rejectionReason,
        faceMatchScore,
        livenessVerified,
      );

  static const documentTypes = {
    'drivers_license': '運転免許証',
    'my_number': 'マイナンバーカード',
    'passport': 'パスポート',
    'residence_card': '在留カード',
  };

  String get documentTypeLabel => documentTypes[documentType] ?? documentType;
}
