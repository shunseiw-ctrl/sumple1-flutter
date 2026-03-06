import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumple1/core/utils/logger.dart';

class PhoneAuthService {
  final FirebaseAuth _auth;
  PhoneAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onAutoVerified,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException) onError,
    int? resendToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          // async コールバックのエラーを安全にハンドル
          try {
            onAutoVerified(credential);
          } catch (e) {
            Logger.error('Auto verification callback error',
                tag: 'PhoneAuthService', error: e);
          }
        },
        verificationFailed: onError,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (_) {},
        forceResendingToken: resendToken,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      // iOS reCAPTCHAフォールバックやAPNs関連のネイティブエラーをキャッチ
      Logger.error('verifyPhoneNumber native error',
          tag: 'PhoneAuthService', error: e);
      rethrow;
    }
  }

  PhoneAuthCredential createCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) {
    return _auth.signInWithCredential(credential);
  }
}
