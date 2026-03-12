import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';

/// 日報アイテム（管理者ビュー用）
class WorkReportItem {
  final String id;
  final String applicationId;
  final String workerUid;
  final String workerName;
  final String jobTitle;
  final String reportDate;
  final String workContent;
  final double hoursWorked;
  final List<String> photoUrls;
  final String reviewStatus; // 'pending' | 'reviewed'
  final String? adminComment;
  final DateTime? createdAt;

  const WorkReportItem({
    required this.id,
    required this.applicationId,
    required this.workerUid,
    this.workerName = '',
    this.jobTitle = '',
    required this.reportDate,
    required this.workContent,
    required this.hoursWorked,
    this.photoUrls = const [],
    this.reviewStatus = 'pending',
    this.adminComment,
    this.createdAt,
  });

  bool get isReviewed => reviewStatus == 'reviewed';
  bool get isPending => reviewStatus == 'pending';

  WorkReportItem copyWith({String? workerName, String? jobTitle, String? reviewStatus, String? adminComment}) {
    return WorkReportItem(
      id: id,
      applicationId: applicationId,
      workerUid: workerUid,
      workerName: workerName ?? this.workerName,
      jobTitle: jobTitle ?? this.jobTitle,
      reportDate: reportDate,
      workContent: workContent,
      hoursWorked: hoursWorked,
      photoUrls: photoUrls,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      adminComment: adminComment ?? this.adminComment,
      createdAt: createdAt,
    );
  }
}

/// 日報管理プロバイダー
final adminWorkReportsProvider = AutoDisposeAsyncNotifierProvider<
    AdminWorkReportsNotifier, AdminListState<WorkReportItem>>(
  AdminWorkReportsNotifier.new,
);

class AdminWorkReportsNotifier
    extends AutoDisposeAsyncNotifier<AdminListState<WorkReportItem>> {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<AdminListState<WorkReportItem>> build() async {
    return _fetch();
  }

  Future<AdminListState<WorkReportItem>> _fetch({
    DocumentSnapshot? startAfter,
    List<WorkReportItem> existing = const [],
  }) async {
    // collectionGroupではorderByを使わない（インデックス不要に）
    final query = _db
        .collectionGroup('work_reports')
        .limit(100);

    final snap = await query.get();
    final newItems = snap.docs.map((doc) {
      final data = doc.data();
      final ts = data['createdAt'];

      return WorkReportItem(
        id: doc.id,
        applicationId: doc.reference.parent.parent?.id ?? '',
        workerUid: (data['workerUid'] ?? '').toString(),
        reportDate: (data['reportDate'] ?? '').toString(),
        workContent: (data['workContent'] ?? '').toString(),
        hoursWorked: _parseDouble(data['hoursWorked']),
        photoUrls: (data['photoUrls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        reviewStatus: (data['reviewStatus'] ?? 'pending').toString(),
        adminComment: data['adminComment']?.toString(),
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

    return AdminListState<WorkReportItem>(
      items: allItems,
      hasMore: false,
    );
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
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

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  void setSearchQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(searchQuery: query));
  }
}
