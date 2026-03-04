import 'package:cloud_firestore/cloud_firestore.dart';

/// ワーカー名をバッチ解決するサービス
class WorkerNameResolver {
  final FirebaseFirestore _db;
  final Map<String, String> _cache = {};

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

  /// キャッシュをクリア
  void clearCache() => _cache.clear();
}
