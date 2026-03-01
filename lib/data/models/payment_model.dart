import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String applicationId;
  final String jobId;
  final String? earningId;
  final String workerUid;
  final String adminUid;
  final int amount;
  final int platformFee;
  final int netAmount;
  final String? stripePaymentIntentId;
  final String status;
  final String payoutStatus;
  final String? projectNameSnapshot;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.applicationId,
    required this.jobId,
    this.earningId,
    required this.workerUid,
    required this.adminUid,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    this.stripePaymentIntentId,
    required this.status,
    required this.payoutStatus,
    this.projectNameSnapshot,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PaymentModel(
      id: doc.id,
      applicationId: data['applicationId']?.toString() ?? '',
      jobId: data['jobId']?.toString() ?? '',
      earningId: data['earningId']?.toString(),
      workerUid: data['workerUid']?.toString() ?? '',
      adminUid: data['adminUid']?.toString() ?? '',
      amount: _parseInt(data['amount']) ?? 0,
      platformFee: _parseInt(data['platformFee']) ?? 0,
      netAmount: _parseInt(data['netAmount']) ?? 0,
      stripePaymentIntentId: data['stripePaymentIntentId']?.toString(),
      status: data['status']?.toString() ?? 'pending',
      payoutStatus: data['payoutStatus']?.toString() ?? 'pending',
      projectNameSnapshot: data['projectNameSnapshot']?.toString(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return '処理中';
      case 'succeeded':
        return '決済完了';
      case 'failed':
        return '決済失敗';
      default:
        return status;
    }
  }

  String get payoutStatusLabel {
    switch (payoutStatus) {
      case 'pending':
        return '振込待ち';
      case 'paid':
        return '振込済み';
      default:
        return payoutStatus;
    }
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
