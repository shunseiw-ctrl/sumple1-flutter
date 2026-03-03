import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

extension QueryTimeout on Query<Map<String, dynamic>> {
  /// Firestoreクエリにタイムアウトを設定し、タイムアウト時はキャッシュにフォールバック
  Future<QuerySnapshot<Map<String, dynamic>>> getWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      return await get().timeout(timeout);
    } on TimeoutException {
      return await get(const GetOptions(source: Source.cache));
    }
  }
}

extension DocumentRefTimeout on DocumentReference<Map<String, dynamic>> {
  /// ドキュメント取得にタイムアウトを設定し、タイムアウト時はキャッシュにフォールバック
  Future<DocumentSnapshot<Map<String, dynamic>>> getWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      return await get().timeout(timeout);
    } on TimeoutException {
      return await get(const GetOptions(source: Source.cache));
    }
  }
}
