import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/logger.dart';

/// Firestore の初期設定
class FirestoreSetup {
  static Future<void> initialize() async {
    try {
      // オフライン永続化を有効化
      final settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      FirebaseFirestore.instance.settings = settings;

      Logger.info(
        'Firestore initialized with offline persistence',
        tag: 'FirestoreSetup',
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to initialize Firestore settings',
        tag: 'FirestoreSetup',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// ネットワーク接続を有効化
  static Future<void> enableNetwork() async {
    try {
      await FirebaseFirestore.instance.enableNetwork();
      Logger.info('Firestore network enabled', tag: 'FirestoreSetup');
    } catch (e) {
      Logger.error(
        'Failed to enable Firestore network',
        tag: 'FirestoreSetup',
        error: e,
      );
    }
  }

  /// ネットワーク接続を無効化（テスト用）
  static Future<void> disableNetwork() async {
    try {
      await FirebaseFirestore.instance.disableNetwork();
      Logger.info('Firestore network disabled', tag: 'FirestoreSetup');
    } catch (e) {
      Logger.error(
        'Failed to disable Firestore network',
        tag: 'FirestoreSetup',
        error: e,
      );
    }
  }

  /// キャッシュをクリア（開発用）
  static Future<void> clearPersistence() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
      Logger.info('Firestore cache cleared', tag: 'FirestoreSetup');
    } catch (e) {
      Logger.error(
        'Failed to clear Firestore cache',
        tag: 'FirestoreSetup',
        error: e,
      );
    }
  }
}
