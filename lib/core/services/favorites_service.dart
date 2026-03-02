import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _db;
  final FirebaseAuth _authInstance;

  FavoritesService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _authInstance = auth ?? FirebaseAuth.instance;

  String? get _uid => _authInstance.currentUser?.uid;
  bool get isRegistered {
    final user = _authInstance.currentUser;
    return user != null && !user.isAnonymous;
  }

  DocumentReference? get _docRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('favorites').doc(uid);
  }

  Future<void> toggleFavorite(String jobId) async {
    if (!isRegistered) return;
    final ref = _docRef;
    if (ref == null) return;

    final doc = await ref.get();
    if (doc.exists) {
      final data = (doc as DocumentSnapshot<Map<String, dynamic>>).data() ?? {};
      final List<String> jobIds = List<String>.from(data['jobIds'] ?? []);
      if (jobIds.contains(jobId)) {
        jobIds.remove(jobId);
      } else {
        jobIds.add(jobId);
      }
      await ref.set({'jobIds': jobIds, 'updatedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.set({'jobIds': [jobId], 'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  Stream<List<String>> favoritesStream() {
    if (!isRegistered) return Stream.value([]);
    final ref = _docRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) {
      final data = (snap as DocumentSnapshot<Map<String, dynamic>>).data();
      if (data == null) return <String>[];
      return List<String>.from(data['jobIds'] ?? []);
    });
  }

  /// Firestore whereIn は最大30件なのでバッチ分割して一括取得
  Future<Map<String, Map<String, dynamic>>> fetchJobsByIds(List<String> jobIds) async {
    if (jobIds.isEmpty) return {};
    final result = <String, Map<String, dynamic>>{};
    const batchSize = 30;
    for (var i = 0; i < jobIds.length; i += batchSize) {
      final batch = jobIds.sublist(i, (i + batchSize).clamp(0, jobIds.length));
      final snap = await _db.collection('jobs')
          .where(FieldPath.documentId, whereIn: batch).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        result[doc.id] = data;
      }
    }
    return result;
  }
}
