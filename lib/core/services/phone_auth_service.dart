import 'package:firebase_auth/firebase_auth.dart';

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
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: onError,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      forceResendingToken: resendToken,
    );
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
