import 'package:cloud_firestore/cloud_firestore.dart';

/// 月次明細の明細行
class StatementLineItem {
  final String applicationId;
  final String jobTitle;
  final String completedDate; // YYYY-MM-DD
  final int amount; // 案件金額

  StatementLineItem({
    required this.applicationId,
    required this.jobTitle,
    required this.completedDate,
    required this.amount,
  });

  factory StatementLineItem.fromMap(Map<String, dynamic> data) {
    return StatementLineItem(
      applicationId: data['applicationId']?.toString() ?? '',
      jobTitle: data['jobTitle']?.toString() ?? '',
      completedDate: data['completedDate']?.toString() ?? '',
      amount: _parseInt(data['amount']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'jobTitle': jobTitle,
      'completedDate': completedDate,
      'amount': amount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatementLineItem &&
          other.applicationId == applicationId &&
          other.jobTitle == jobTitle &&
          other.completedDate == completedDate &&
          other.amount == amount);

  @override
  int get hashCode =>
      Object.hash(applicationId, jobTitle, completedDate, amount);

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// 月次支払明細モデル
class MonthlyStatementModel {
  final String id;
  final String workerUid;
  final String month; // YYYY-MM
  final List<StatementLineItem> items;
  final int totalAmount;
  final int netAmount; // 職人受取額
  final String status; // 'draft' | 'confirmed' | 'paid'
  final String? paymentDate; // 翌月10日
  final bool earlyPaymentRequested;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MonthlyStatementModel({
    required this.id,
    required this.workerUid,
    required this.month,
    this.items = const [],
    required this.totalAmount,
    required this.netAmount,
    this.status = 'draft',
    this.paymentDate,
    this.earlyPaymentRequested = false,
    this.createdAt,
    this.updatedAt,
  });

  String get statusLabel => switch (status) {
        'draft' => '集計中',
        'confirmed' => '確定済み',
        'paid' => '支払済み',
        _ => status,
      };

  factory MonthlyStatementModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return MonthlyStatementModel.fromMap(doc.id, data);
  }

  factory MonthlyStatementModel.fromMap(
      String id, Map<String, dynamic> data) {
    return MonthlyStatementModel(
      id: id,
      workerUid: data['workerUid']?.toString() ?? '',
      month: data['month']?.toString() ?? '',
      items: _parseItems(data['items']),
      totalAmount: _parseInt(data['totalAmount']) ?? 0,
      netAmount: _parseInt(data['netAmount']) ?? 0,
      status: data['status']?.toString() ?? 'draft',
      paymentDate: data['paymentDate']?.toString(),
      earlyPaymentRequested: data['earlyPaymentRequested'] == true,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workerUid': workerUid,
      'month': month,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'netAmount': netAmount,
      'status': status,
      if (paymentDate != null) 'paymentDate': paymentDate,
      'earlyPaymentRequested': earlyPaymentRequested,
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
      (other is MonthlyStatementModel &&
          other.id == id &&
          other.workerUid == workerUid &&
          other.month == month &&
          other.totalAmount == totalAmount &&
          other.netAmount == netAmount &&
          other.status == status &&
          other.paymentDate == paymentDate &&
          other.earlyPaymentRequested == earlyPaymentRequested &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(
        id,
        workerUid,
        month,
        totalAmount,
        netAmount,
        status,
        paymentDate,
        earlyPaymentRequested,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'MonthlyStatementModel(id: $id, month: $month, status: $status, total: $totalAmount)';
  }

  static List<StatementLineItem> _parseItems(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((m) => StatementLineItem.fromMap(m))
          .toList();
    }
    return [];
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
