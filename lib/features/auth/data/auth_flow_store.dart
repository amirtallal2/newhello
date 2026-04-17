final class AuthFlowStore {
  AuthFlowStore._();

  static final AuthFlowStore instance = AuthFlowStore._();

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

  void savePendingRegistration({
    required String registrationToken,
    required String email,
    required String maskedEmail,
    String? emailCode,
  }) {
    pendingRegistrationToken = registrationToken;
    pendingEmail = email;
    pendingMaskedEmail = maskedEmail;
    debugEmailCode = emailCode;
  }

  void savePendingPhoneOtp({required String phone, required String otp}) {
    pendingPhone = phone;
    debugPhoneOtp = otp;
  }

  void savePasswordReset({
    required String token,
    required String maskedEmail,
    String? resetCode,
  }) {
    passwordResetToken = token;
    passwordResetMaskedEmail = maskedEmail;
    passwordResetCode = resetCode;
  }

  void saveAuthSession({
    required String token,
    required Map<String, dynamic> user,
  }) {
    authToken = token;
    currentUser = user;
  }

  void clearPendingRegistration() {
    pendingRegistrationToken = null;
    pendingEmail = null;
    pendingMaskedEmail = null;
    pendingPhone = null;
    debugEmailCode = null;
    debugPhoneOtp = null;
  }

  void clearPasswordReset() {
    passwordResetToken = null;
    passwordResetCode = null;
    passwordResetMaskedEmail = null;
  }

  void clearSession() {
    authToken = null;
    currentUser = null;
  }

  void reset() {
    clearPendingRegistration();
    clearPasswordReset();
    clearSession();
  }
}
