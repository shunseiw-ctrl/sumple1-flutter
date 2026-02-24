import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../utils/logger.dart';

class FirestoreSetup {
  static Future<void> initialize() async {
    try {
      final settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: kIsWeb ? 40 * 1024 * 1024 : Settings.CACHE_SIZE_UNLIMITED,
      );

      FirebaseFirestore.instance.settings = settings;

      Logger.info(
        'Firestore initialized',
        tag: 'FirestoreSetup',
        data: {
          'persistence': true,
          'cacheSize': kIsWeb ? '40MB' : 'unlimited',
          'platform': kIsWeb ? 'web' : 'native',
        },
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
