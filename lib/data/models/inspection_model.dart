import 'package:cloud_firestore/cloud_firestore.dart';

/// 検査チェック項目
class InspectionCheckItem {
  final String label; // 例: "仕上がり品質", "清掃状況"
  final String result; // 'pass' | 'fail' | 'na'
  final String? comment; // 項目別コメント（max 500文字）

  InspectionCheckItem({
    required this.label,
    required this.result,
    this.comment,
  });

  factory InspectionCheckItem.fromMap(Map<String, dynamic> data) {
    return InspectionCheckItem(
      label: data['label']?.toString() ?? '',
      result: data['result']?.toString() ?? 'na',
      comment: data['comment']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'result': result,
      if (comment != null) 'comment': comment,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InspectionCheckItem &&
          other.label == label &&
          other.result == result &&
          other.comment == comment);

  @override
  int get hashCode => Object.hash(label, result, comment);
}

/// 検査（Inspection）のデータモデル
class InspectionModel {
  final String id;
  final String applicationId;
  final String inspectorUid;
  final String result; // 'passed' | 'failed' | 'partial'
  final List<InspectionCheckItem> items;
  final List<String> photoUrls; // 検査証拠写真
  final String? overallComment; // 総合コメント（max 2000文字）
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InspectionModel({
    required this.id,
    required this.applicationId,
    required this.inspectorUid,
    required this.result,
    this.items = const [],
    this.photoUrls = const [],
    this.overallComment,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPassed => result == 'passed';
  bool get hasFailed => items.any((i) => i.result == 'fail');

  /// 建設業デフォルトチェックリスト
  static const List<String> defaultCheckItems = [
    '仕上がり品質',
    '寸法精度',
    '清掃状況',
    '安全措置',
    '資材管理',
    '近隣配慮',
  ];

  factory InspectionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return InspectionModel.fromMap(doc.id, data);
  }

  factory InspectionModel.fromMap(String id, Map<String, dynamic> data) {
    return InspectionModel(
      id: id,
      applicationId: data['applicationId']?.toString() ?? '',
      inspectorUid: data['inspectorUid']?.toString() ?? '',
      result: data['result']?.toString() ?? 'failed',
      items: _parseItems(data['items']),
      photoUrls: _parseStringList(data['photoUrls']),
      overallComment: data['overallComment']?.toString(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'inspectorUid': inspectorUid,
      'result': result,
      'items': items.map((i) => i.toMap()).toList(),
      'photoUrls': photoUrls,
      if (overallComment != null) 'overallComment': overallComment,
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
      (other is InspectionModel &&
          other.id == id &&
          other.applicationId == applicationId &&
          other.inspectorUid == inspectorUid &&
          other.result == result &&
          other.overallComment == overallComment &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode => Object.hash(
        id,
        applicationId,
        inspectorUid,
        result,
        overallComment,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'InspectionModel(id: $id, result: $result, items: ${items.length})';
  }

  static List<InspectionCheckItem> _parseItems(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((m) => InspectionCheckItem.fromMap(m))
          .toList();
    }
    return [];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
