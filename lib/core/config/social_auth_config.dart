import 'dart:io';

abstract final class SocialAuthConfig {
  static const String _defaultGoogleServerClientId =
      '920413815879-apmg5tgaalgir8j7d5tn64tcnveg52g9.apps.googleusercontent.com';

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: _defaultGoogleServerClientId,
  );

  static bool get showAppleSignIn => Platform.isIOS;

  static bool get isGoogleConfigured => googleServerClientId.trim().isNotEmpty;
}
