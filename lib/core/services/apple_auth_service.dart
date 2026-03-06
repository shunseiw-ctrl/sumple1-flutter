import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../utils/logger.dart';
import 'analytics_service.dart';

class AppleAuthService {
  AppleAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// SHA256 nonce を生成
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// nonce の SHA256 ハッシュ
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with Apple 実行
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonceSha256 = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonceSha256,
      );

      if (appleCredential.identityToken == null) {
        throw Exception('Apple identity token is null');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        // Apple は初回のみ名前を返す — 保存する
        String displayName = user.displayName ?? '';
        if (displayName.isEmpty &&
            appleCredential.givenName != null &&
            appleCredential.familyName != null) {
          displayName =
              '${appleCredential.familyName} ${appleCredential.givenName}';
          await user.updateDisplayName(displayName);
        }

        await _saveProfile(user, displayName, appleCredential.email);
        AnalyticsService.logLogin('apple');
      }

      Logger.info('Apple sign in successful', tag: 'AppleAuthService');
      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled ||
          e.code == AuthorizationErrorCode.unknown) {
        Logger.info('Apple sign in cancelled by user',
            tag: 'AppleAuthService');
        return null;
      }
      Logger.error('Apple authorization error',
          tag: 'AppleAuthService', error: e);
      rethrow;
    } catch (e) {
      Logger.error('Apple sign in failed', tag: 'AppleAuthService', error: e);
      rethrow;
    }
  }

  Future<void> _saveProfile(
      User user, String displayName, String? email) async {
    try {
      await _db.doc('profiles/${user.uid}').set({
        'displayName': displayName.isNotEmpty ? displayName : '',
        'email': email ?? user.email ?? '',
        'provider': 'apple',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      Logger.warning('Failed to save Apple profile',
          tag: 'AppleAuthService');
    }
  }
}
