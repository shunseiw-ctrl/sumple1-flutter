import 'package:cloud_firestore/cloud_firestore.dart';

/// ページネーション結果を保持するモデル
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  /// 空の結果を返す
  factory PaginatedResult.empty() {
    return const PaginatedResult(items: [], hasMore: false);
  }
}
