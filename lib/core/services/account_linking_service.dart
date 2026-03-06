import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';
import '../constants/google_auth_constants.dart';

/// リンク操作の結果
class LinkResult {
  final bool success;
  final bool needsMerge;
  final AuthCredential? credential;
  final String? conflictingEmail;

  /// リンク成功
  const LinkResult.success()
      : success = true,
        needsMerge = false,
        credential = null,
        conflictingEmail = null;

  /// キャンセル（成功でもマージでもない）
  const LinkResult.cancelled()
      : success = false,
        needsMerge = false,
        credential = null,
        conflictingEmail = null;

  /// マージが必要
  const LinkResult.merge({
    required AuthCredential this.credential,
    required String this.conflictingEmail,
  })  : success = false,
        needsMerge = true;
}

/// アカウントリンキングサービス
/// Google/Apple/LINE プロバイダーのリンク・リンク解除を管理
class AccountLinkingService {
  AccountLinkingService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: GoogleAuthConstants.iosClientId,
              serverClientId: GoogleAuthConstants.webClientId,
            ),
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;
  final FirebaseFunctions _functions;

  /// Google アカウントをリンク
  Future<LinkResult> linkGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return const LinkResult.cancelled();

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);

      await _updateLinkedProviders(user);
      Logger.info('Google account linked', tag: 'AccountLinkingService');
      return const LinkResult.success();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        Logger.warning(
            'Google credential already in use', tag: 'AccountLinkingService');
        // Google Sign-Inからemailを取得
        final googleUser = await _googleSignIn.signInSilently();
        final email = googleUser?.email ?? e.email;
        if (email != null && e.credential != null) {
          return LinkResult.merge(
            credential: e.credential!,
            conflictingEmail: email,
          );
        }
        rethrow;
      }
      Logger.error('Google link failed',
          tag: 'AccountLinkingService', error: e);
      rethrow;
    }
  }

  /// Apple アカウントをリンク
  Future<LinkResult> linkApple() async {
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

      if (appleCredential.identityToken == null) {
        throw Exception('Apple identity token is null');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      await user.linkWithCredential(oauthCredential);

      await _updateLinkedProviders(user);
      Logger.info('Apple account linked', tag: 'AccountLinkingService');
      return const LinkResult.success();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled ||
          e.code == AuthorizationErrorCode.unknown) {
        return const LinkResult.cancelled();
      }
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        Logger.warning(
            'Apple credential already in use', tag: 'AccountLinkingService');
        // Apple JWT (identityToken) からemailを抽出
        final email = e.email ?? _extractEmailFromCredential(e);
        if (email != null && e.credential != null) {
          return LinkResult.merge(
            credential: e.credential!,
            conflictingEmail: email,
          );
        }
        rethrow;
      }
      Logger.error('Apple link failed',
          tag: 'AccountLinkingService', error: e);
      rethrow;
    }
  }

  /// Email アカウントをリンク
  Future<LinkResult> linkEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(credential);

      await _updateLinkedProviders(user);
      Logger.info('Email account linked', tag: 'AccountLinkingService');
      return const LinkResult.success();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        Logger.warning(
            'Email credential already in use', tag: 'AccountLinkingService');
        if (e.credential != null && e.email != null) {
          return LinkResult.merge(
            credential: e.credential!,
            conflictingEmail: e.email!,
          );
        }
        rethrow;
      }
      Logger.error('Email link failed',
          tag: 'AccountLinkingService', error: e);
      rethrow;
    }
  }

  /// Phone アカウントをリンク
  Future<LinkResult> linkPhone({
    required PhoneAuthCredential credential,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      await user.linkWithCredential(credential);

      await _updateLinkedProviders(user);
      Logger.info('Phone account linked', tag: 'AccountLinkingService');
      return const LinkResult.success();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        Logger.warning(
            'Phone credential already in use', tag: 'AccountLinkingService');
        // Phone にはemailがないのでマージ不可→rethrow
        rethrow;
      }
      Logger.error('Phone link failed',
          tag: 'AccountLinkingService', error: e);
      rethrow;
    }
  }

  /// CF mergeAccounts 呼び出し → linkWithCredential 再試行
  Future<void> mergeAndLink(AuthCredential credential,
      String conflictingEmail) async {
    final callable = _functions.httpsCallable('mergeAccounts');
    await callable.call({'conflictingEmail': conflictingEmail});

    // マージ完了後にリンク再試行
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    await user.linkWithCredential(credential);
    await _updateLinkedProviders(user);
    Logger.info('Account merged and linked', tag: 'AccountLinkingService');
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
      Logger.warning('Failed to update linkedProviders',
          tag: 'AccountLinkingService');
    }
  }

  /// FirebaseAuthException からemailを抽出（Apple用フォールバック）
  String? _extractEmailFromCredential(FirebaseAuthException e) {
    // FirebaseAuthException.email が最優先
    if (e.email != null) return e.email;
    return null;
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
            length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
