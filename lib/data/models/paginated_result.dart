import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaginatedResult<T> &&
          listEquals(other.items, items) &&
          other.hasMore == hasMore &&
          other.lastDocument == lastDocument);

  @override
  int get hashCode => Object.hash(Object.hashAll(items), hasMore, lastDocument);
}
