import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/social_auth_config.dart';

final class GoogleAuthSession {
  const GoogleAuthSession({
    required this.idToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String idToken;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

final class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  bool _isInitialized = false;

  Future<GoogleAuthSession> signIn() async {
    _validateConfiguration();
    await _ensureInitialized();

    final GoogleSignInAccount account = await GoogleSignIn.instance
        .authenticate();
    final String? idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return a usable ID token.');
    }

    return GoogleAuthSession(
      idToken: idToken,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  Future<void> signOut() async {
    if (!_isInitialized) {
      return;
    }

    await GoogleSignIn.instance.signOut();
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }

    await GoogleSignIn.instance.initialize(
      clientId: SocialAuthConfig.googleClientId.trim().isEmpty
          ? null
          : SocialAuthConfig.googleClientId.trim(),
      serverClientId: SocialAuthConfig.googleServerClientId.trim().isEmpty
          ? null
          : SocialAuthConfig.googleServerClientId.trim(),
    );
    _isInitialized = true;
  }

  void _validateConfiguration() {
    if (Platform.isAndroid &&
        SocialAuthConfig.googleServerClientId.trim().isEmpty) {
      throw StateError(
        'Google sign-in on Android requires GOOGLE_SERVER_CLIENT_ID to be your WEB OAuth client ID. Do not use the Android client ID here.',
      );
    }

    if (Platform.isIOS &&
        (SocialAuthConfig.googleClientId.trim().isEmpty ||
            SocialAuthConfig.googleServerClientId.trim().isEmpty)) {
      throw StateError(
        'Google sign-in on iOS requires GOOGLE_CLIENT_ID and GOOGLE_SERVER_CLIENT_ID.',
      );
    }
  }
}
