import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftModel {
  final String id;
  final String date;
  final String qrCode;
  final String createdBy;
  final DateTime? createdAt;

  ShiftModel({
    required this.id,
    required this.date,
    required this.qrCode,
    required this.createdBy,
    this.createdAt,
  });

  factory ShiftModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ShiftModel(
      id: doc.id,
      date: data['date']?.toString() ?? '',
      qrCode: data['qrCode']?.toString() ?? '',
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  factory ShiftModel.fromMap(String id, Map<String, dynamic> data) {
    return ShiftModel(
      id: id,
      date: data['date']?.toString() ?? '',
      qrCode: data['qrCode']?.toString() ?? '',
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'date': date,
      'qrCode': qrCode,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
