import 'package:cloud_firestore/cloud_firestore.dart';

extension OfflineAwareQuery on Query<Map<String, dynamic>> {
  /// サーバー優先でデータを取得し、失敗時にキャッシュにフォールバック
  Future<QuerySnapshot<Map<String, dynamic>>> getWithFallback() async {
    try {
      return await get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      return await get(const GetOptions(source: Source.cache));
    }
  }
}

extension OfflineAwareDocRef on DocumentReference<Map<String, dynamic>> {
  /// サーバー優先でドキュメントを取得し、失敗時にキャッシュにフォールバック
  Future<DocumentSnapshot<Map<String, dynamic>>> getWithFallback() async {
    try {
      return await get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      return await get(const GetOptions(source: Source.cache));
    }
  }
}
