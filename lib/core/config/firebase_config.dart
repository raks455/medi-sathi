/// Google Sign-In client IDs. Copy them from:
///   Firebase console -> Authentication -> Sign-in method -> Google
///   -> Web SDK configuration -> "Web client ID"      (googleServerClientId)
///   GoogleService-Info.plist -> CLIENT_ID            (googleIosClientId, iOS only)
class FirebaseConfig {
  FirebaseConfig._();

  /// REQUIRED on Android so Google returns an ID token.
  static const googleServerClientId = '842846129563-diifn1mhts4a64kfoqphdrhi9a8sn08n.apps.googleusercontent.com';

  /// Needed on iOS only. Leave empty on Android.
  static const googleIosClientId = '';
}
