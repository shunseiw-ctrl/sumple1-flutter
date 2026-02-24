import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get isRegistered {
    final user = FirebaseAuth.instance.currentUser;
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
}
