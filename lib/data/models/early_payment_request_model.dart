import 'package:cloud_firestore/cloud_firestore.dart';

/// 即金申請モデル
class EarlyPaymentRequestModel {
  final String id;
  final String workerUid;
  final String statementId;
  final String month;
  final int requestedAmount;
  final int earlyPaymentFee; // requestedAmount * 0.10
  final int payoutAmount; // requestedAmount - fee
  final String status; // 'requested' | 'approved' | 'rejected' | 'paid'
  final String? reviewedBy;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EarlyPaymentRequestModel({
    required this.id,
    required this.workerUid,
    required this.statementId,
    required this.month,
    required this.requestedAmount,
    required this.earlyPaymentFee,
    required this.payoutAmount,
    this.status = 'requested',
    this.reviewedBy,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  /// 手数料率 10%
  static const double feeRate = 0.10;

  /// 手数料を計算
  static int calculateFee(int amount) => (amount * feeRate).round();

  /// 受取額を計算
  static int calculatePayout(int amount) => amount - calculateFee(amount);

  String get statusLabel => switch (status) {
        'requested' => '申請中',
        'approved' => '承認済み',
        'rejected' => '却下',
        'paid' => '支払済み',
        _ => status,
      };

  factory EarlyPaymentRequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return EarlyPaymentRequestModel.fromMap(doc.id, data);
  }

  factory EarlyPaymentRequestModel.fromMap(
      String id, Map<String, dynamic> data) {
    return EarlyPaymentRequestModel(
      id: id,
      workerUid: data['workerUid']?.toString() ?? '',
      statementId: data['statementId']?.toString() ?? '',
      month: data['month']?.toString() ?? '',
      requestedAmount: _parseInt(data['requestedAmount']) ?? 0,
      earlyPaymentFee: _parseInt(data['earlyPaymentFee']) ?? 0,
      payoutAmount: _parseInt(data['payoutAmount']) ?? 0,
      status: data['status']?.toString() ?? 'requested',
      reviewedBy: data['reviewedBy']?.toString(),
      rejectionReason: data['rejectionReason']?.toString(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerUid': workerUid,
      'statementId': statementId,
      'month': month,
      'requestedAmount': requestedAmount,
      'earlyPaymentFee': earlyPaymentFee,
      'payoutAmount': payoutAmount,
      'status': status,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarlyPaymentRequestModel &&
          other.id == id &&
          other.workerUid == workerUid &&
          other.statementId == statementId &&
          other.month == month &&
          other.requestedAmount == requestedAmount &&
          other.earlyPaymentFee == earlyPaymentFee &&
          other.payoutAmount == payoutAmount &&
          other.status == status &&
          other.reviewedBy == reviewedBy &&
          other.rejectionReason == rejectionReason &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(
        id,
        workerUid,
        statementId,
        month,
        requestedAmount,
        earlyPaymentFee,
        payoutAmount,
        status,
        reviewedBy,
        rejectionReason,
      );

  @override
  String toString() {
    return 'EarlyPaymentRequestModel(id: $id, amount: $requestedAmount, fee: $earlyPaymentFee, status: $status)';
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
