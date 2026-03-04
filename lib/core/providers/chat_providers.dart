import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 未読チャット数プロバイダー
/// BottomNavのメッセージタブバッジに使用
final unreadChatCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.isAnonymous) {
    return Stream.value(0);
  }

  final uid = user.uid;

  // applicationsからチャットIDを取得→chatsの未読を集計
  return FirebaseFirestore.instance
      .collection('applications')
      .where('applicantUid', isEqualTo: uid)
      .snapshots()
      .asyncMap((appSnap) async {
    if (appSnap.docs.isEmpty) return 0;

    final appIds = appSnap.docs.map((d) => d.id).toList();
    int totalUnread = 0;

    // whereInは最大30件なのでバッチ処理
    const batchSize = 30;
    for (var i = 0; i < appIds.length; i += batchSize) {
      final batch = appIds.sublist(
        i,
        (i + batchSize).clamp(0, appIds.length),
      );
      final chatSnap = await FirebaseFirestore.instance
          .collection('chats')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in chatSnap.docs) {
        final data = doc.data();
        final unread = data['unreadCountApplicant'];
        if (unread is int && unread > 0) {
          totalUnread += unread;
        }
      }
    }
    return totalUnread;
  });
});
