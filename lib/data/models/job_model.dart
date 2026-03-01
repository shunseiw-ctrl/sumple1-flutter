import 'package:cloud_firestore/cloud_firestore.dart';

/// 案件（Job）のデータモデル
class JobModel {
  final String id;
  final String title;
  final String location;
  final String prefecture;
  final int price;
  final String date;
  final String? workMonthKey; // YYYY-MM形式
  final String? ownerId;
  final String? description;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JobModel({
    required this.id,
    required this.title,
    required this.location,
    required this.prefecture,
    required this.price,
    required this.date,
    this.workMonthKey,
    this.ownerId,
    this.description,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  /// Firestoreドキュメントからモデルを生成
  factory JobModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    return JobModel(
      id: doc.id,
      title: data['title']?.toString() ?? 'タイトルなし',
      location: data['location']?.toString() ?? '未設定',
      prefecture: data['prefecture']?.toString() ?? '未設定',
      price: _parseInt(data['price']) ?? 0,
      date: data['date']?.toString() ?? '未設定',
      workMonthKey: data['workMonthKey']?.toString(),
      ownerId: data['ownerId']?.toString(),
      description: data['description']?.toString(),
      latitude: _parseDouble(data['latitude']),
      longitude: _parseDouble(data['longitude']),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  /// Mapからモデルを生成
  factory JobModel.fromMap(String id, Map<String, dynamic> data) {
    return JobModel(
      id: id,
      title: data['title']?.toString() ?? 'タイトルなし',
      location: data['location']?.toString() ?? '未設定',
      prefecture: data['prefecture']?.toString() ?? '未設定',
      price: _parseInt(data['price']) ?? 0,
      date: data['date']?.toString() ?? '未設定',
      workMonthKey: data['workMonthKey']?.toString(),
      ownerId: data['ownerId']?.toString(),
      description: data['description']?.toString(),
      latitude: _parseDouble(data['latitude']),
      longitude: _parseDouble(data['longitude']),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  /// Firestoreに保存する形式に変換
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'prefecture': prefecture,
      'price': price,
      'date': date,
      if (workMonthKey != null) 'workMonthKey': workMonthKey,
      if (ownerId != null) 'ownerId': ownerId,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// 新規作成用のMap
  Map<String, dynamic> toCreateMap() {
    return {
      ...toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// ownerIdが設定されているか
  bool get hasOwner => ownerId != null && ownerId!.isNotEmpty;

  /// 指定されたユーザーがオーナーか
  bool isOwner(String userId) {
    return hasOwner && ownerId == userId;
  }

  /// コピーを作成
  JobModel copyWith({
    String? id,
    String? title,
    String? location,
    String? prefecture,
    int? price,
    String? date,
    String? workMonthKey,
    String? ownerId,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      prefecture: prefecture ?? this.prefecture,
      price: price ?? this.price,
      date: date ?? this.date,
      workMonthKey: workMonthKey ?? this.workMonthKey,
      ownerId: ownerId ?? this.ownerId,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobModel &&
          other.id == id &&
          other.title == title &&
          other.location == location &&
          other.prefecture == prefecture &&
          other.price == price &&
          other.date == date &&
          other.workMonthKey == workMonthKey &&
          other.ownerId == ownerId &&
          other.description == description &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        location,
        prefecture,
        price,
        date,
        workMonthKey,
        ownerId,
        description,
        latitude,
        longitude,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'JobModel(id: $id, title: $title, location: $location, price: $price)';
  }

  // ヘルパーメソッド

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
