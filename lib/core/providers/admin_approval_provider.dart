import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';

/// 承認アイテムの種別
enum ApprovalType { qualification, earlyPayment, verification }

/// 承認アイテム共通データクラス
class ApprovalItem {
  final String id;
  final String workerUid;
  final ApprovalType type;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final String? parentPath;

  const ApprovalItem({
    required this.id,
    required this.workerUid,
    required this.type,
    required this.data,
    this.createdAt,
    this.parentPath,
  });
}

/// 承認タブごとのデータを提供するプロバイダーファミリー
final adminApprovalProvider = AutoDisposeAsyncNotifierProvider.family<
    AdminApprovalNotifier, AdminListState<ApprovalItem>, ApprovalType>(
  AdminApprovalNotifier.new,
);

class AdminApprovalNotifier extends AutoDisposeFamilyAsyncNotifier<
    AdminListState<ApprovalItem>, ApprovalType> {
  static const _pageSize = 20;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<AdminListState<ApprovalItem>> build(ApprovalType arg) async {
    return _fetch(arg);
  }

  Future<AdminListState<ApprovalItem>> _fetch(
    ApprovalType type, {
    DocumentSnapshot? startAfter,
    List<ApprovalItem> existing = const [],
  }) async {
    Query<Map<String, dynamic>> query;

    switch (type) {
      case ApprovalType.qualification:
        query = _db
            .collectionGroup('qualifications_v2')
            .where('verificationStatus', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true);
        break;
      case ApprovalType.earlyPayment:
        query = _db
            .collection('early_payment_requests')
            .where('status', isEqualTo: 'requested')
            .orderBy('createdAt', descending: true);
        break;
      case ApprovalType.verification:
        query = _db
            .collection('identity_verification')
            .where('status', isEqualTo: 'pending')
            .orderBy('submittedAt', descending: false);
        break;
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(_pageSize);

    final snap = await query.get();
    final newItems = snap.docs.map((doc) {
      final data = doc.data();
      String workerUid;

      switch (type) {
        case ApprovalType.qualification:
          // collectionGroupでは親パスからUIDを取得
          workerUid = doc.reference.parent.parent?.id ?? '';
          break;
        case ApprovalType.earlyPayment:
          workerUid = (data['workerUid'] ?? '').toString();
          break;
        case ApprovalType.verification:
          workerUid = doc.id;
          break;
      }

      DateTime? createdAt;
      final tsField = type == ApprovalType.verification ? 'submittedAt' : 'createdAt';
      final ts = data[tsField];
      if (ts is Timestamp) {
        createdAt = ts.toDate();
      }

      return ApprovalItem(
        id: doc.id,
        workerUid: workerUid,
        type: type,
        data: data,
        createdAt: createdAt,
        parentPath: type == ApprovalType.qualification
            ? doc.reference.parent.parent?.path
            : null,
      );
    }).toList();

    final allItems = [...existing, ...newItems];

    return AdminListState<ApprovalItem>(
      items: allItems,
      hasMore: snap.docs.length >= _pageSize,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final newState = await _fetch(
        arg,
        startAfter: current.lastDocument,
        existing: current.items,
      );
      state = AsyncValue.data(newState.copyWith(isLoadingMore: false));
    } catch (e, st) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  void removeItem(String itemId) {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(
      items: current.items.where((i) => i.id != itemId).toList(),
    ));
  }
}
