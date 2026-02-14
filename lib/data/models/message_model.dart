import 'package:cloud_firestore/cloud_firestore.dart';

/// メッセージ（Message）のデータモデル
class MessageModel {
  final String id;
  final String senderUid;
  final String text;
  final DateTime? createdAt;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.text,
    this.createdAt,
  });

  /// Firestoreドキュメントからモデルを生成
  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    return MessageModel(
      id: doc.id,
      senderUid: data['senderUid']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  /// Mapからモデルを生成
  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderUid: data['senderUid']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  /// Firestoreに保存する形式に変換
  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// 指定されたユーザーが送信者か
  bool isSender(String userId) {
    return senderUid == userId;
  }

  /// メッセージが空でないか
  bool get isNotEmpty => text.trim().isNotEmpty;

  /// コピーを作成
  MessageModel copyWith({
    String? id,
    String? senderUid,
    String? text,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderUid: senderUid ?? this.senderUid,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, sender: $senderUid, text: $text)';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
