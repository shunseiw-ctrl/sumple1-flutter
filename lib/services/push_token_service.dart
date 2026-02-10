import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushTokenService {
  static Future<void> syncFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messaging = FirebaseMessaging.instance;

    // Android 13+ / iOS 対応（権限）
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;

    final ref = FirebaseFirestore.instance.collection('profiles').doc(user.uid);

    // ✅ rulesのupdate許可キーに完全一致（fcmToken, updatedAt のみ）
    try {
      await ref.set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('[PushTokenService] fcmToken saved uid=${user.uid.substring(0, user.uid.length > 8 ? 8 : user.uid.length)}…');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PushTokenService] failed to save fcmToken: $e');
      }
    }
  }
}
