import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';

/// 検査アイテム（管理者ビュー用）
class InspectionItem {
  final String id;
  final String applicationId;
  final String inspectorUid;
  final String result;
  final int totalItems;
  final int passedItems;
  final String? overallComment;
  final DateTime? createdAt;
  final String workerName;
  final String jobTitle;

  const InspectionItem({
    required this.id,
    required this.applicationId,
    required this.inspectorUid,
    required this.result,
    required this.totalItems,
    required this.passedItems,
    this.overallComment,
    this.createdAt,
    this.workerName = '',
    this.jobTitle = '',
  });

  InspectionItem copyWith({String? workerName, String? jobTitle}) {
    return InspectionItem(
      id: id,
      applicationId: applicationId,
      inspectorUid: inspectorUid,
      result: result,
      totalItems: totalItems,
      passedItems: passedItems,
      overallComment: overallComment,
      createdAt: createdAt,
      workerName: workerName ?? this.workerName,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }
}

/// 検査管理プロバイダー
final adminInspectionsProvider = AutoDisposeAsyncNotifierProvider<
    AdminInspectionsNotifier, AdminListState<InspectionItem>>(
  AdminInspectionsNotifier.new,
);

class AdminInspectionsNotifier
    extends AutoDisposeAsyncNotifier<AdminListState<InspectionItem>> {
  static const _pageSize = 20;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String _filterResult = 'all';

  @override
  Future<AdminListState<InspectionItem>> build() async {
    return _fetch();
  }

  Future<AdminListState<InspectionItem>> _fetch({
    DocumentSnapshot? startAfter,
    List<InspectionItem> existing = const [],
  }) async {
    // collectionGroupではorderByを使わない（インデックス不要に）
    Query<Map<String, dynamic>> query = _db.collectionGroup('inspections');

    if (_filterResult != 'all') {
      query = query.where('result', isEqualTo: _filterResult);
    }

    query = query.limit(100);

    final snap = await query.get();
    final newItems = snap.docs.map((doc) {
      final data = doc.data();
      final ts = data['createdAt'];
      final items = (data['items'] as List<dynamic>?) ?? [];
      final passedCount = items.where((i) {
        if (i is Map<String, dynamic>) {
          return i['result'] == 'pass';
        }
        return false;
      }).length;

      return InspectionItem(
        id: doc.id,
        applicationId: doc.reference.parent.parent?.id ?? '',
        inspectorUid: (data['inspectorUid'] ?? '').toString(),
        result: (data['result'] ?? '').toString(),
        totalItems: items.length,
        passedItems: passedCount,
        overallComment: data['overallComment']?.toString(),
        createdAt: ts is Timestamp ? ts.toDate() : null,
      );
    }).toList();

    final allItems = [...existing, ...newItems];
    // クライアント側でソート（createdAtの降順）
    allItems.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(2000);
      final bTime = b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return AdminListState<InspectionItem>(
      items: allItems,
      hasMore: false,
      filterStatus: _filterResult,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final newState = await _fetch(
        startAfter: current.lastDocument,
        existing: current.items,
      );
      state = AsyncValue.data(newState.copyWith(isLoadingMore: false));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setFilter(String result) async {
    _filterResult = result;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}
