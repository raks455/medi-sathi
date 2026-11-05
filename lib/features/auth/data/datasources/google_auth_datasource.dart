import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/firebase_config.dart';
import '../../../../core/error/exceptions.dart';

abstract class GoogleAuthDataSource {
  /// Opens the Google account picker, signs in to Firebase, and returns a
  /// Firebase ID token for the MediSathi backend to verify.
  Future<String> signInAndGetFirebaseIdToken();

  Future<void> signOut();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  bool _initialized = false;

  GoogleAuthDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  // google_sign_in 7.x must be initialized once before authenticate().
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    await googleSignIn.initialize(
      clientId: isIos && FirebaseConfig.googleIosClientId.isNotEmpty
          ? FirebaseConfig.googleIosClientId
          : null,
      serverClientId: FirebaseConfig.googleServerClientId.isNotEmpty
          ? FirebaseConfig.googleServerClientId
          : null,
    );
    _initialized = true;
  }

  @override
  Future<String> signInAndGetFirebaseIdToken() async {
    try {
      await _ensureInitialized();

      final account = await googleSignIn.authenticate();
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null) {
        throw ServerException(
            'Google did not return an ID token. Check the Web client ID in firebase_config.dart.');
      }

      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
      final result = await firebaseAuth.signInWithCredential(credential);

      final firebaseToken = await result.user?.getIdToken();
      if (firebaseToken == null) {
        throw ServerException('Could not get a Firebase token.');
      }
      return firebaseToken;
    } on GoogleSignInException catch (e) {
      final code = e.code.name;
      if (code == 'canceled' || code == 'interrupted') {
        throw AuthCancelledException();
      }
      throw ServerException('Google sign-in failed ($code). Please try again.');
    } on FirebaseAuthException catch (e) {
      throw ServerException(_firebaseMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }

  String _firebaseMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }
}
