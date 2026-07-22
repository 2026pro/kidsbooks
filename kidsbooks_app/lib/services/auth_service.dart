import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = Provider((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authProvider).authStateChanges());

final currentUidProvider = Provider<String?>(
    (ref) => ref.watch(authStateProvider).value?.uid);

/// Phone OTP sign-in (primary flow for Mongolia).
class PhoneAuthService {
  PhoneAuthService(this._auth);
  final FirebaseAuth _auth;

  Future<void> startVerification({
    required String phoneE164, // e.g. +97699112233
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onError,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      verificationCompleted: (cred) => _auth.signInWithCredential(cred),
      verificationFailed: onError,
      codeSent: (id, _) => onCodeSent(id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> confirmCode(String verificationId, String smsCode) {
    final cred = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    return _auth.signInWithCredential(cred);
  }
}

final phoneAuthServiceProvider =
    Provider((ref) => PhoneAuthService(ref.watch(authProvider)));
