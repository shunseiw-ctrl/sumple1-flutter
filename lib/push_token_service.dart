import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

    // profileが無くても作る（merge）
    await ref.set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
      'email': user.email,
    }, SetOptions(merge: true));
  }
}
