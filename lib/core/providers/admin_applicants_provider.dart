import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/worker_name_resolver.dart';
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
  final double? qualityScore;
  final String locationSnapshot;
  final String dateSnapshot;
  final int? priceSnapshot;
  final String photoUrl;
  final int verifiedQualificationCount;
  final int completedJobCount;
  final String ekycStatus; // 'none' | 'pending' | 'approved' | 'rejected'

  const ApplicantItem({
    required this.id,
    required this.jobTitle,
    required this.status,
    required this.applicantUid,
    this.createdAt,
    this.workerName = '',
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.qualityScore,
    this.locationSnapshot = '',
    this.dateSnapshot = '',
    this.priceSnapshot,
    this.photoUrl = '',
    this.verifiedQualificationCount = 0,
    this.completedJobCount = 0,
    this.ekycStatus = 'none',
  });

  ApplicantItem copyWith({
    String? id,
    String? jobTitle,
    String? status,
    String? applicantUid,
    DateTime? createdAt,
    String? workerName,
    double? ratingAverage,
    int? ratingCount,
    double? qualityScore,
    String? locationSnapshot,
    String? dateSnapshot,
    int? priceSnapshot,
    String? photoUrl,
    int? verifiedQualificationCount,
    int? completedJobCount,
    String? ekycStatus,
  }) {
    return ApplicantItem(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      status: status ?? this.status,
      applicantUid: applicantUid ?? this.applicantUid,
      createdAt: createdAt ?? this.createdAt,
      workerName: workerName ?? this.workerName,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      qualityScore: qualityScore ?? this.qualityScore,
      locationSnapshot: locationSnapshot ?? this.locationSnapshot,
      dateSnapshot: dateSnapshot ?? this.dateSnapshot,
      priceSnapshot: priceSnapshot ?? this.priceSnapshot,
      photoUrl: photoUrl ?? this.photoUrl,
      verifiedQualificationCount:
          verifiedQualificationCount ?? this.verifiedQualificationCount,
      completedJobCount: completedJobCount ?? this.completedJobCount,
      ekycStatus: ekycStatus ?? this.ekycStatus,
    );
  }
}

/// 応募者リスト AsyncNotifier
class AdminApplicantsNotifier
    extends AutoDisposeAsyncNotifier<AdminListState<ApplicantItem>> {
  static const int _pageSize = 20;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final FirebaseFirestore _db;
  final WorkerNameResolver _resolver;

  AdminApplicantsNotifier({FirebaseFirestore? firestore, WorkerNameResolver? resolver})
      : _db = firestore ?? FirebaseFirestore.instance,
        _resolver = resolver ?? WorkerNameResolver(firestore: firestore);

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
        .listen((snap) async {
      final current = state.valueOrNull;
      if (current == null) return;

      final freshItems = await _docsToItems(snap.docs);
      // マージ: 初回ページのみリアルタイム更新、それ以降は維持
      final existingIds = freshItems.map((e) => e.id).toSet();
      final olderItems =
          current.items.where((e) => !existingIds.contains(e.id)).toList();

      state = AsyncData(current.copyWith(
        items: [...freshItems, ...olderItems],
      ));
    });
  }

  Future<List<ApplicantItem>> _docsToItems(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final items = docs.map((doc) {
      final data = doc.data();
      final createdAt = data['createdAt'];
      DateTime? dt;
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      }
      final priceRaw = data['priceSnapshot'];
      final priceInt =
          (priceRaw is int) ? priceRaw : int.tryParse('$priceRaw');

      return ApplicantItem(
        id: doc.id,
        jobTitle: (data['jobTitleSnapshot'] ?? '案件名なし').toString(),
        status: (data['status'] ?? 'applied').toString(),
        applicantUid: (data['applicantUid'] ?? '').toString(),
        createdAt: dt,
        workerName: (data['workerNameSnapshot'] ?? '').toString(),
        ratingAverage: (data['ratingAverageSnapshot'] ?? 0).toDouble(),
        ratingCount: (data['ratingCountSnapshot'] as num?)?.toInt() ?? 0,
        locationSnapshot: (data['locationSnapshot'] ?? '').toString(),
        dateSnapshot: (data['dateSnapshot'] ?? '').toString(),
        priceSnapshot: priceInt,
      );
    }).toList();

    // 空名のUIDを収集してバッチ解決 + プロフィール情報取得
    final uidsNeedingInfo = items
        .map((i) => i.applicantUid)
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList();

    if (uidsNeedingInfo.isEmpty) return items;

    try {
      final profiles = await _resolver.resolveProfiles(uidsNeedingInfo);

      // 資格数バッチ取得（承認済み）
      final qualCounts = <String, int>{};
      final completedCounts = <String, int>{};
      for (var i = 0; i < uidsNeedingInfo.length; i += 10) {
        final batch = uidsNeedingInfo.skip(i).take(10).toList();
        for (final uid in batch) {
          try {
            final qualSnap = await _db
                .collection('profiles')
                .doc(uid)
                .collection('qualifications_v2')
                .where('verificationStatus', isEqualTo: 'approved')
                .get();
            qualCounts[uid] = qualSnap.docs.length;
          } catch (_) {
            qualCounts[uid] = 0;
          }

          try {
            final completedSnap = await _db
                .collection('applications')
                .where('applicantUid', isEqualTo: uid)
                .where('status', isEqualTo: 'done')
                .get();
            completedCounts[uid] = completedSnap.docs.length;
          } catch (_) {
            completedCounts[uid] = 0;
          }
        }
      }

      return items.map((item) {
        final profile = profiles[item.applicantUid];
        final resolvedName = (item.workerName.isEmpty && profile != null)
            ? profile.name
            : item.workerName;

        return item.copyWith(
          workerName: resolvedName,
          photoUrl: profile?.photoUrl ?? '',
          ekycStatus: profile?.ekycStatus ?? 'none',
          verifiedQualificationCount: qualCounts[item.applicantUid] ?? 0,
          completedJobCount: completedCounts[item.applicantUid] ?? 0,
        );
      }).toList();
    } catch (_) {
      return items;
    }
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
      final newItems = await _docsToItems(snap.docs);

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
