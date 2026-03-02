import 'package:cloud_firestore/cloud_firestore.dart';

/// 管理者リスト共通状態モデル
///
/// ページネーション、フィルタ、検索の状態を汎用的に管理。
class AdminListState<T> {
  final List<T> items;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchQuery;
  final String filterStatus;
  final DocumentSnapshot? lastDocument;

  const AdminListState({
    this.items = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filterStatus = 'all',
    this.lastDocument,
  });

  AdminListState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
    String? filterStatus,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
  }) {
    return AdminListState<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      lastDocument: clearLastDocument ? null : (lastDocument ?? this.lastDocument),
    );
  }

  /// 検索クエリでアイテムをフィルタリング
  List<T> filteredItems(bool Function(T item, String query) matcher) {
    if (searchQuery.isEmpty) return items;
    return items.where((item) => matcher(item, searchQuery)).toList();
  }
}
