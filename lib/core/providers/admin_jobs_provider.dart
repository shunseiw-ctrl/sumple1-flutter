import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_list_state.dart';

/// 案件データモデル（プロバイダー用）
class JobItem {
  final String id;
  final String title;
  final String location;
  final int price;
  final String date;
  final String status;
  final int applicantCount;
  final int? slots;
  final DateTime? createdAt;

  const JobItem({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.date,
    required this.status,
    this.applicantCount = 0,
    this.slots,
    this.createdAt,
  });
}

/// 案件一覧 AsyncNotifier
class AdminJobsNotifier
    extends AutoDisposeAsyncNotifier<AdminListState<JobItem>> {
  static const int _pageSize = 20;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final FirebaseFirestore _db;

  AdminJobsNotifier({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  FutureOr<AdminListState<JobItem>> build() async {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    final items = await _fetchInitialPage();
    _listenToRealtimeUpdates();

    return AdminListState<JobItem>(
      items: items,
      hasMore: items.length >= _pageSize,
    );
  }

  Future<List<JobItem>> _fetchInitialPage() async {
    final snap = await _db
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .get();

    return _docsToItems(snap.docs);
  }

  void _listenToRealtimeUpdates() {
    _subscription?.cancel();
    _subscription = _db
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen((snap) {
      final current = state.valueOrNull;
      if (current == null) return;

      final freshItems = _docsToItems(snap.docs);
      final existingIds = freshItems.map((e) => e.id).toSet();
      final olderItems =
          current.items.where((e) => !existingIds.contains(e.id)).toList();

      state = AsyncData(current.copyWith(
        items: [...freshItems, ...olderItems],
      ));
    });
  }

  List<JobItem> _docsToItems(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      final createdAt = data['createdAt'];
      DateTime? dt;
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      }
      final priceRaw = data['price'];
      final price =
          (priceRaw is int) ? priceRaw : int.tryParse('$priceRaw') ?? 0;

      return JobItem(
        id: doc.id,
        title: (data['title'] ?? '').toString(),
        location: (data['location'] ?? '').toString(),
        price: price,
        date: (data['date'] ?? '').toString(),
        status: (data['status'] ?? 'active').toString(),
        applicantCount: (data['applicantCount'] ?? 0) as int,
        slots: data['slots'] as int?,
        createdAt: dt,
      );
    }).toList();
  }

  /// ページネーション: 追加取得
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      var query = _db
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (current.items.isNotEmpty) {
        final lastItem = current.items.last;
        if (lastItem.createdAt != null) {
          query = query
              .startAfter([Timestamp.fromDate(lastItem.createdAt!)]);
        }
      }

      final snap = await query.get();
      final newItems = _docsToItems(snap.docs);

      state = AsyncData(current.copyWith(
        items: [...current.items, ...newItems],
        hasMore: newItems.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// フィルタ変更
  void setFilter(String status) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(filterStatus: status));
  }

  /// 検索クエリ変更
  void setSearchQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: query));
  }

  /// 全件リロード
  Future<void> refresh() async {
    _subscription?.cancel();
    state = const AsyncLoading();
    final items = await _fetchInitialPage();
    _listenToRealtimeUpdates();
    state = AsyncData(AdminListState<JobItem>(
      items: items,
      hasMore: items.length >= _pageSize,
    ));
  }
}

/// プロバイダー定義
final adminJobsProvider = AsyncNotifierProvider.autoDispose<
    AdminJobsNotifier, AdminListState<JobItem>>(AdminJobsNotifier.new);
