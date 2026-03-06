import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/logger.dart';
import '../constants/google_auth_constants.dart';
import 'analytics_service.dart';

class GoogleAuthService {

  GoogleAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: GoogleAuthConstants.iosClientId,
              serverClientId: GoogleAuthConstants.webClientId,
            );

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // ユーザーがキャンセル
        Logger.info('Google sign in cancelled', tag: 'GoogleAuthService');
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _saveProfile(user, googleUser.email);
        try {
          await AnalyticsService.logLogin('google');
        } catch (_) {
          // テスト環境ではFirebase Analytics未初期化のため無視
        }
      }

      Logger.info('Google sign in successful', tag: 'GoogleAuthService');
      return userCredential;
    } catch (e) {
      Logger.error('Google sign in failed',
          tag: 'GoogleAuthService', error: e);
      rethrow;
    }
  }

  Future<void> _saveProfile(User user, String email) async {
    await _db.doc('profiles/${user.uid}').set({
      'displayName': user.displayName ?? '',
      'email': email,
      'photoUrl': user.photoURL ?? '',
      'provider': 'google',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
