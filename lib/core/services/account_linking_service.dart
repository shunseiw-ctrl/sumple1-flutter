import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';

/// アカウントリンキングサービス
/// Google/Apple/LINE プロバイダーのリンク・リンク解除を管理
class AccountLinkingService {
  static const String _iosClientId =
      '319960355608-svkte1q6p25mv675qqf8a0di89mi85lk.apps.googleusercontent.com';
  static const String _webClientId =
      '319960355608-pfuh6qe42hqtbm372ti9egv3r99bbh0k.apps.googleusercontent.com';

  AccountLinkingService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: _iosClientId,
              serverClientId: _webClientId,
            );

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  /// Google アカウントをリンク
  Future<void> linkGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // キャンセル

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);

      await _updateLinkedProviders(user);
      Logger.info('Google account linked', tag: 'AccountLinkingService');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        Logger.warning('Google credential already in use', tag: 'AccountLinkingService');
        rethrow;
      }
      Logger.error('Google link failed', tag: 'AccountLinkingService', error: e);
      rethrow;
    }
  }

  /// Apple アカウントをリンク
  Future<void> linkApple() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final rawNonce = _generateNonce();
      final nonceSha256 = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonceSha256,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      await user.linkWithCredential(oauthCredential);

      await _updateLinkedProviders(user);
      Logger.info('Apple account linked', tag: 'AccountLinkingService');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        Logger.warning('Apple credential already in use', tag: 'AccountLinkingService');
        rethrow;
      }
      Logger.error('Apple link failed', tag: 'AccountLinkingService', error: e);
      rethrow;
    }
  }

  /// リンク済みプロバイダー一覧を取得
  List<String> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];

    final providers = <String>[];
    for (final info in user.providerData) {
      providers.add(info.providerId);
    }

    // LINE ユーザーはカスタムトークンでサインインしているため providerData にない
    // UID が 'line:' で始まる場合、LINE をリンク済みとして追加
    if (user.uid.startsWith('line:')) {
      providers.add('line');
    }

    return providers;
  }

  /// プロバイダーのリンクを解除
  Future<void> unlinkProvider(String providerId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    // 最低1つのプロバイダーが必要
    final linkedCount = getLinkedProviders().length;
    if (linkedCount <= 1) {
      throw Exception('cannot_unlink_last');
    }

    await user.unlink(providerId);

    await _updateLinkedProviders(user);
    Logger.info('Provider unlinked: $providerId', tag: 'AccountLinkingService');
  }

  /// Firestore プロフィールの linkedProviders を更新
  Future<void> _updateLinkedProviders(User user) async {
    try {
      final providers = getLinkedProviders();
      await _db.doc('profiles/${user.uid}').set({
        'linkedProviders': providers,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      Logger.warning('Failed to update linkedProviders', tag: 'AccountLinkingService');
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
