import 'package:cloud_firestore/cloud_firestore.dart';

/// 紹介コードのデータモデル
class ReferralModel {
  final String code;
  final String referrerUid;
  final String refereeUid;
  final String status; // "pending" | "completed"
  final bool rewardGranted;
  final DateTime createdAt;

  const ReferralModel({
    required this.code,
    required this.referrerUid,
    required this.refereeUid,
    required this.status,
    required this.rewardGranted,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'code': code,
        'referrerUid': referrerUid,
        'refereeUid': refereeUid,
        'status': status,
        'rewardGranted': rewardGranted,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ReferralModel.fromMap(Map<String, dynamic> map) {
    return ReferralModel(
      code: map['code']?.toString() ?? '',
      referrerUid: map['referrerUid']?.toString() ?? '',
      refereeUid: map['refereeUid']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      rewardGranted: map['rewardGranted'] == true,
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferralModel &&
          other.code == code &&
          other.referrerUid == referrerUid &&
          other.refereeUid == refereeUid &&
          other.status == status &&
          other.rewardGranted == rewardGranted &&
          other.createdAt == createdAt);

  @override
  int get hashCode => Object.hash(
        code,
        referrerUid,
        refereeUid,
        status,
        rewardGranted,
        createdAt,
      );

  @override
  String toString() {
    return 'ReferralModel(code: $code, referrer: $referrerUid, referee: $refereeUid, status: $status)';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
