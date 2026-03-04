import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';

/// アクティブワーカーアイテム
class ActiveWorkerItem {
  final String uid;
  final String name;
  final int activeJobCount;
  final String latestJobTitle;
  final String status;
  final double qualityScore;

  const ActiveWorkerItem({
    required this.uid,
    required this.name,
    required this.activeJobCount,
    this.latestJobTitle = '',
    this.status = '',
    this.qualityScore = 0,
  });
}

/// 稼働中ワーカープロバイダー
final adminActiveWorkersProvider = AutoDisposeAsyncNotifierProvider<
    AdminActiveWorkersNotifier, AdminListState<ActiveWorkerItem>>(
  AdminActiveWorkersNotifier.new,
);

class AdminActiveWorkersNotifier
    extends AutoDisposeAsyncNotifier<AdminListState<ActiveWorkerItem>> {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<AdminListState<ActiveWorkerItem>> build() async {
    return _fetch();
  }

  Future<AdminListState<ActiveWorkerItem>> _fetch() async {
    // 稼働中・割当済みの応募を取得
    final snap = await _db
        .collection('applications')
        .where('status', whereIn: ['assigned', 'in_progress'])
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();

    // ワーカーUIDごとにグルーピング
    final workerMap = <String, List<Map<String, dynamic>>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final uid = (data['applicantUid'] ?? '').toString();
      if (uid.isNotEmpty) {
        workerMap.putIfAbsent(uid, () => []).add(data);
      }
    }

    // ワーカー名を一括取得
    final uids = workerMap.keys.toList();
    final names = <String, String>{};

    for (var i = 0; i < uids.length; i += 10) {
      final batch = uids.skip(i).take(10).toList();
      try {
        final profilesSnap = await _db
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in profilesSnap.docs) {
          final data = doc.data();
          final displayName = (data['displayName'] ?? '').toString().trim();
          if (displayName.isNotEmpty) {
            names[doc.id] = displayName;
            continue;
          }
          final familyName = (data['familyName'] ?? '').toString().trim();
          final givenName = (data['givenName'] ?? '').toString().trim();
          if (familyName.isNotEmpty || givenName.isNotEmpty) {
            names[doc.id] = '$familyName $givenName'.trim();
            continue;
          }
          names[doc.id] = '';
        }
      } catch (_) {}
    }

    final workers = workerMap.entries.map((entry) {
      final uid = entry.key;
      final apps = entry.value;
      final latestTitle = (apps.first['jobTitleSnapshot'] ?? '').toString();
      final status = apps.any((a) => a['status'] == 'in_progress')
          ? 'in_progress'
          : 'assigned';

      return ActiveWorkerItem(
        uid: uid,
        name: names[uid] ?? '',
        activeJobCount: apps.length,
        latestJobTitle: latestTitle,
        status: status,
      );
    }).toList();

    // アクティブ案件数の降順でソート
    workers.sort((a, b) => b.activeJobCount.compareTo(a.activeJobCount));

    return AdminListState<ActiveWorkerItem>(
      items: workers,
      hasMore: false,
    );
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
