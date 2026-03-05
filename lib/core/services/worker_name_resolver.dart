import 'package:cloud_firestore/cloud_firestore.dart';

/// ワーカープロフィールのスナップショット（名前、写真、eKYC）
class WorkerProfileSnapshot {
  final String name;
  final String photoUrl;
  final String ekycStatus; // 'none' | 'pending' | 'approved' | 'rejected'

  const WorkerProfileSnapshot({
    this.name = '',
    this.photoUrl = '',
    this.ekycStatus = 'none',
  });
}

/// ワーカー名をバッチ解決するサービス
class WorkerNameResolver {
  final FirebaseFirestore _db;
  final Map<String, String> _cache = {};
  final Map<String, WorkerProfileSnapshot> _profileCache = {};

  WorkerNameResolver({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// 単一UIDのワーカー名を解決
  Future<String> resolve(String uid) async {
    if (_cache.containsKey(uid)) return _cache[uid]!;

    try {
      final doc = await _db.collection('profiles').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final name = buildDisplayName(data);
        if (name.isNotEmpty) {
          _cache[uid] = name;
          return name;
        }
      }
    } catch (_) {}

    _cache[uid] = '';
    return '';
  }

  /// 複数UIDのワーカー名をバッチ解決（whereIn は10件制限なので分割）
  Future<Map<String, String>> resolveNames(List<String> uids) async {
    final result = <String, String>{};
    final uncachedUids = <String>[];

    for (final uid in uids) {
      if (_cache.containsKey(uid)) {
        result[uid] = _cache[uid]!;
      } else {
        uncachedUids.add(uid);
      }
    }

    if (uncachedUids.isEmpty) return result;

    // whereIn は最大10件なので分割
    for (var i = 0; i < uncachedUids.length; i += 10) {
      final batch = uncachedUids.skip(i).take(10).toList();
      try {
        final snap = await _db
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snap.docs) {
          final name = buildDisplayName(doc.data());
          _cache[doc.id] = name;
          result[doc.id] = name;
        }
      } catch (_) {}

      // キャッシュにないUIDは空文字をセット
      for (final uid in batch) {
        if (!result.containsKey(uid)) {
          _cache[uid] = '';
          result[uid] = '';
        }
      }
    }

    return result;
  }

  /// プロフィールデータから表示名を構築
  static String buildDisplayName(Map<String, dynamic> data) {
    final displayName = (data['displayName'] ?? '').toString().trim();
    if (displayName.isNotEmpty) return displayName;

    final familyName = (data['familyName'] ?? '').toString().trim();
    final givenName = (data['givenName'] ?? '').toString().trim();
    if (familyName.isNotEmpty || givenName.isNotEmpty) {
      return '$familyName $givenName'.trim();
    }
    return '';
  }

  /// 複数UIDのプロフィール情報をバッチ取得（名前・写真・eKYC）
  Future<Map<String, WorkerProfileSnapshot>> resolveProfiles(
      List<String> uids) async {
    final result = <String, WorkerProfileSnapshot>{};
    final uncachedUids = <String>[];

    for (final uid in uids) {
      if (_profileCache.containsKey(uid)) {
        result[uid] = _profileCache[uid]!;
      } else {
        uncachedUids.add(uid);
      }
    }

    if (uncachedUids.isEmpty) return result;

    // profiles取得（10件ずつ分割）
    final profileData = <String, Map<String, dynamic>>{};
    for (var i = 0; i < uncachedUids.length; i += 10) {
      final batch = uncachedUids.skip(i).take(10).toList();
      try {
        final snap = await _db
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snap.docs) {
          profileData[doc.id] = doc.data();
        }
      } catch (_) {}
    }

    // identity_verification取得（10件ずつ分割）
    final ekycData = <String, String>{};
    for (var i = 0; i < uncachedUids.length; i += 10) {
      final batch = uncachedUids.skip(i).take(10).toList();
      try {
        final snap = await _db
            .collection('identity_verification')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snap.docs) {
          ekycData[doc.id] = (doc.data()['status'] ?? 'pending').toString();
        }
      } catch (_) {}
    }

    // 結合
    for (final uid in uncachedUids) {
      final data = profileData[uid];
      final name = data != null ? buildDisplayName(data) : '';
      final photoUrl = (data?['photoUrl'] ?? '').toString();
      final ekyc = ekycData[uid] ?? 'none';

      final snapshot = WorkerProfileSnapshot(
        name: name,
        photoUrl: photoUrl,
        ekycStatus: ekyc,
      );
      _profileCache[uid] = snapshot;
      result[uid] = snapshot;

      // 名前キャッシュにも反映
      if (!_cache.containsKey(uid)) {
        _cache[uid] = name;
      }
    }

    return result;
  }

  /// キャッシュをクリア
  void clearCache() {
    _cache.clear();
    _profileCache.clear();
  }
}
