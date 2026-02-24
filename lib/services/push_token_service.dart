import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/utils/logger.dart';

class PushTokenService {
  static Future<void> syncFcmToken() async {
    if (kIsWeb) {
      Logger.info('FCM token sync skipped on Web platform', tag: 'PushTokenService');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Logger.warning('FCM token sync skipped: user not logged in', tag: 'PushTokenService');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        Logger.warning(
          'FCM permission not granted',
          tag: 'PushTokenService',
          data: {'status': settings.authorizationStatus.toString()},
        );
        return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        Logger.warning('FCM token is null or empty', tag: 'PushTokenService');
        return;
      }

      final ref = FirebaseFirestore.instance.collection('profiles').doc(user.uid);

      await ref.set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Logger.info(
        'FCM token saved',
        tag: 'PushTokenService',
        data: {'uid': user.uid.substring(0, user.uid.length > 8 ? 8 : user.uid.length)},
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to sync FCM token',
        tag: 'PushTokenService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
