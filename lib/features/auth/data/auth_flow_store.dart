import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class AuthFlowStore {
  AuthFlowStore._();

  static final AuthFlowStore instance = AuthFlowStore._();

  static const String _pendingRegistrationTokenKey =
      'auth.pending_registration_token';
  static const String _pendingEmailKey = 'auth.pending_email';
  static const String _pendingMaskedEmailKey = 'auth.pending_masked_email';
  static const String _pendingPhoneKey = 'auth.pending_phone';
  static const String _debugEmailCodeKey = 'auth.debug_email_code';
  static const String _debugPhoneOtpKey = 'auth.debug_phone_otp';
  static const String _passwordResetTokenKey = 'auth.password_reset_token';
  static const String _passwordResetCodeKey = 'auth.password_reset_code';
  static const String _passwordResetMaskedEmailKey =
      'auth.password_reset_masked_email';
  static const String _authTokenKey = 'auth.token';
  static const String _currentUserKey = 'auth.current_user';

  SharedPreferences? _preferences;

  String? pendingRegistrationToken;
  String? pendingEmail;
  String? pendingMaskedEmail;
  String? pendingPhone;
  String? debugEmailCode;
  String? debugPhoneOtp;

  String? passwordResetToken;
  String? passwordResetCode;
  String? passwordResetMaskedEmail;

  String? authToken;
  Map<String, dynamic>? currentUser;

  bool get hasActiveSession =>
      authToken != null &&
      authToken!.isNotEmpty &&
      currentUser != null &&
      currentUser!.isNotEmpty;

  Future<void> initialize() async {
    final preferences = await _prefs();
    pendingRegistrationToken = preferences.getString(
      _pendingRegistrationTokenKey,
    );
    pendingEmail = preferences.getString(_pendingEmailKey);
    pendingMaskedEmail = preferences.getString(_pendingMaskedEmailKey);
    pendingPhone = preferences.getString(_pendingPhoneKey);
    debugEmailCode = preferences.getString(_debugEmailCodeKey);
    debugPhoneOtp = preferences.getString(_debugPhoneOtpKey);
    passwordResetToken = preferences.getString(_passwordResetTokenKey);
    passwordResetCode = preferences.getString(_passwordResetCodeKey);
    passwordResetMaskedEmail = preferences.getString(
      _passwordResetMaskedEmailKey,
    );
    authToken = preferences.getString(_authTokenKey);

    final rawUser = preferences.getString(_currentUserKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      currentUser = Map<String, dynamic>.from(
        jsonDecode(rawUser) as Map<String, dynamic>,
      );
    }
  }

  Future<void> savePendingRegistration({
    required String registrationToken,
    required String email,
    required String maskedEmail,
    String? emailCode,
  }) async {
    pendingRegistrationToken = registrationToken;
    pendingEmail = email;
    pendingMaskedEmail = maskedEmail;
    debugEmailCode = emailCode;
    await _persistPendingRegistration();
  }

  Future<void> savePendingPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    pendingPhone = phone;
    debugPhoneOtp = otp;
    await _persistPendingRegistration();
  }

  Future<void> savePasswordReset({
    required String token,
    required String maskedEmail,
    String? resetCode,
  }) async {
    passwordResetToken = token;
    passwordResetMaskedEmail = maskedEmail;
    passwordResetCode = resetCode;
    await _persistPasswordReset();
  }

  Future<void> saveAuthSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    authToken = token;
    currentUser = user;
    await _persistSession();
  }

  Future<void> clearPendingRegistration() async {
    pendingRegistrationToken = null;
    pendingEmail = null;
    pendingMaskedEmail = null;
    pendingPhone = null;
    debugEmailCode = null;
    debugPhoneOtp = null;
    await _persistPendingRegistration();
  }

  Future<void> clearPasswordReset() async {
    passwordResetToken = null;
    passwordResetCode = null;
    passwordResetMaskedEmail = null;
    await _persistPasswordReset();
  }

  Future<void> clearSession() async {
    authToken = null;
    currentUser = null;
    await _persistSession();
  }

  Future<void> reset() async {
    pendingRegistrationToken = null;
    pendingEmail = null;
    pendingMaskedEmail = null;
    pendingPhone = null;
    debugEmailCode = null;
    debugPhoneOtp = null;
    passwordResetToken = null;
    passwordResetCode = null;
    passwordResetMaskedEmail = null;
    authToken = null;
    currentUser = null;

    final preferences = await _prefs();
    await preferences.remove(_pendingRegistrationTokenKey);
    await preferences.remove(_pendingEmailKey);
    await preferences.remove(_pendingMaskedEmailKey);
    await preferences.remove(_pendingPhoneKey);
    await preferences.remove(_debugEmailCodeKey);
    await preferences.remove(_debugPhoneOtpKey);
    await preferences.remove(_passwordResetTokenKey);
    await preferences.remove(_passwordResetCodeKey);
    await preferences.remove(_passwordResetMaskedEmailKey);
    await preferences.remove(_authTokenKey);
    await preferences.remove(_currentUserKey);
  }

  Future<void> _persistPendingRegistration() async {
    final preferences = await _prefs();
    await _setOrRemove(
      preferences,
      _pendingRegistrationTokenKey,
      pendingRegistrationToken,
    );
    await _setOrRemove(preferences, _pendingEmailKey, pendingEmail);
    await _setOrRemove(preferences, _pendingMaskedEmailKey, pendingMaskedEmail);
    await _setOrRemove(preferences, _pendingPhoneKey, pendingPhone);
    await _setOrRemove(preferences, _debugEmailCodeKey, debugEmailCode);
    await _setOrRemove(preferences, _debugPhoneOtpKey, debugPhoneOtp);
  }

  Future<void> _persistPasswordReset() async {
    final preferences = await _prefs();
    await _setOrRemove(preferences, _passwordResetTokenKey, passwordResetToken);
    await _setOrRemove(preferences, _passwordResetCodeKey, passwordResetCode);
    await _setOrRemove(
      preferences,
      _passwordResetMaskedEmailKey,
      passwordResetMaskedEmail,
    );
  }

  Future<void> _persistSession() async {
    final preferences = await _prefs();
    await _setOrRemove(preferences, _authTokenKey, authToken);

    if (currentUser == null || currentUser!.isEmpty) {
      await preferences.remove(_currentUserKey);
      return;
    }

    await preferences.setString(_currentUserKey, jsonEncode(currentUser));
  }

  Future<void> _setOrRemove(
    SharedPreferences preferences,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await preferences.remove(key);
      return;
    }

    await preferences.setString(key, value);
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }
}
