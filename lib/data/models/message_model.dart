import 'package:cloud_firestore/cloud_firestore.dart';

/// メッセージ（Message）のデータモデル
class MessageModel {
  final String id;
  final String senderUid;
  final String text;
  final String? imageUrl;
  final String messageType;
  final DateTime? createdAt;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.text,
    this.imageUrl,
    this.messageType = 'text',
    this.createdAt,
  });

  /// 画像メッセージか
  bool get isImage => messageType == 'image';

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
      imageUrl: data['imageUrl']?.toString(),
      messageType: data['messageType']?.toString() ?? 'text',
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  /// Mapからモデルを生成
  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderUid: data['senderUid']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      messageType: data['messageType']?.toString() ?? 'text',
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  /// Firestoreに保存する形式に変換
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'senderUid': senderUid,
      'text': text,
      'messageType': messageType,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      map['imageUrl'] = imageUrl;
    }
    return map;
  }

  /// 指定されたユーザーが送信者か
  bool isSender(String userId) {
    return senderUid == userId;
  }

  /// メッセージが空でないか（テキストOR画像があればtrue）
  bool get isNotEmpty =>
      text.trim().isNotEmpty ||
      (imageUrl != null && imageUrl!.isNotEmpty);

  /// コピーを作成
  MessageModel copyWith({
    String? id,
    String? senderUid,
    String? text,
    String? imageUrl,
    String? messageType,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderUid: senderUid ?? this.senderUid,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageModel &&
          other.id == id &&
          other.senderUid == senderUid &&
          other.text == text &&
          other.imageUrl == imageUrl &&
          other.messageType == messageType &&
          other.createdAt == createdAt);

  @override
  int get hashCode =>
      Object.hash(id, senderUid, text, imageUrl, messageType, createdAt);

  @override
  String toString() {
    return 'MessageModel(id: $id, sender: $senderUid, type: $messageType, text: $text)';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
