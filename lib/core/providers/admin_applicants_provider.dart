import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_list_state.dart';

/// 応募データモデル（プロバイダー用）
class ApplicantItem {
  final String id;
  final String jobTitle;
  final String status;
  final String applicantUid;
  final DateTime? createdAt;
  final String workerName;
  final double ratingAverage;
  final int ratingCount;

  const ApplicantItem({
    required this.id,
    required this.jobTitle,
    required this.status,
    required this.applicantUid,
    this.createdAt,
    this.workerName = '',
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });
}

/// 応募者リスト AsyncNotifier
class AdminApplicantsNotifier
    extends AutoDisposeAsyncNotifier<AdminListState<ApplicantItem>> {
  static const int _pageSize = 20;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final FirebaseFirestore _db;

  AdminApplicantsNotifier({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  FutureOr<AdminListState<ApplicantItem>> build() async {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    final items = await _fetchInitialPage();
    _listenToRealtimeUpdates();

    return AdminListState<ApplicantItem>(
      items: items,
      hasMore: items.length >= _pageSize,
    );
  }

  Future<List<ApplicantItem>> _fetchInitialPage() async {
    final snap = await _db
        .collection('applications')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .get();

    return _docsToItems(snap.docs);
  }

  void _listenToRealtimeUpdates() {
    _subscription?.cancel();
    _subscription = _db
        .collection('applications')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen((snap) {
      final current = state.valueOrNull;
      if (current == null) return;

      final freshItems = _docsToItems(snap.docs);
      // マージ: 初回ページのみリアルタイム更新、それ以降は維持
      final existingIds = freshItems.map((e) => e.id).toSet();
      final olderItems =
          current.items.where((e) => !existingIds.contains(e.id)).toList();

      state = AsyncData(current.copyWith(
        items: [...freshItems, ...olderItems],
      ));
    });
  }

  List<ApplicantItem> _docsToItems(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      final createdAt = data['createdAt'];
      DateTime? dt;
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      }
      return ApplicantItem(
        id: doc.id,
        jobTitle: (data['jobTitleSnapshot'] ?? '案件名なし').toString(),
        status: (data['status'] ?? 'applied').toString(),
        applicantUid: (data['applicantUid'] ?? '').toString(),
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
          .collection('applications')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (current.items.isNotEmpty) {
        // 最後のアイテムのcreatedAtでstartAfter
        final lastItem = current.items.last;
        if (lastItem.createdAt != null) {
          query = query.startAfter(
              [Timestamp.fromDate(lastItem.createdAt!)]);
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

  /// 検索クエリ変更（クライアント側フィルタ）
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
    state = AsyncData(AdminListState<ApplicantItem>(
      items: items,
      hasMore: items.length >= _pageSize,
    ));
  }
}

/// プロバイダー定義
final adminApplicantsProvider = AsyncNotifierProvider.autoDispose<
    AdminApplicantsNotifier,
    AdminListState<ApplicantItem>>(AdminApplicantsNotifier.new);
