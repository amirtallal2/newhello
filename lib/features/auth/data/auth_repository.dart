import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'auth_flow_store.dart';

abstract class AuthRepository {
  static AuthRepository instance = LiveAuthRepository();

  Future<bool> restoreSession();

  Future<void> signUp({required String email, required String password});

  Future<String?> resendEmailVerification();

  Future<void> verifyEmail();

  Future<String?> completeIdentity({
    required String nickname,
    required String phone,
    required String birthdate,
    required String gender,
    required String country,
  });

  Future<void> verifyPhoneOtp(String otp);

  Future<void> loginWithEmail({
    required String email,
    required String password,
  });

  Future<void> loginWithPhone({
    required String phone,
    required String password,
  });

  Future<void> loginWithGoogle({
    required String idToken,
    String? serverAuthCode,
  });

  Future<String?> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String password,
    required String confirmPassword,
  });
}

final class LiveAuthRepository implements AuthRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _store = AuthFlowStore.instance;

  @override
  Future<bool> restoreSession() async {
    if (!_store.hasActiveSession) {
      return false;
    }

    try {
      final response = await _client.get(
        '/auth/me',
        bearerToken: _store.authToken,
      );
      final data = response['data'] as Map<String, dynamic>;
      await _store.saveAuthSession(
        token: _store.authToken!,
        user: Map<String, dynamic>.from(data),
      );
      return true;
    } catch (_) {
      await _store.clearSession();
      return false;
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    final response = await _client.post(
      '/auth/register',
      body: {'email': email, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    await _store.savePendingRegistration(
      registrationToken: data['registration_token'].toString(),
      email: data['email'].toString(),
      maskedEmail: data['email_masked'].toString(),
      emailCode: data['debug_email_code']?.toString(),
    );
  }

  @override
  Future<String?> resendEmailVerification() async {
    final registrationToken = _store.pendingRegistrationToken;
    if (registrationToken == null) {
      throw ApiException('No pending registration found.');
    }

    final response = await _client.post(
      '/auth/email/resend',
      body: {'registration_token': registrationToken},
    );

    final data = response['data'] as Map<String, dynamic>;
    _store.pendingMaskedEmail = data['email_masked']?.toString();
    _store.debugEmailCode = data['debug_email_code']?.toString();

    return _store.debugEmailCode;
  }

  @override
  Future<void> verifyEmail() async {
    final registrationToken = _store.pendingRegistrationToken;
    if (registrationToken == null) {
      throw ApiException('No pending registration found.');
    }

    await _client.post(
      '/auth/email/verify',
      body: {'registration_token': registrationToken},
    );
  }

  @override
  Future<String?> completeIdentity({
    required String nickname,
    required String phone,
    required String birthdate,
    required String gender,
    required String country,
  }) async {
    final registrationToken = _store.pendingRegistrationToken;
    if (registrationToken == null) {
      throw ApiException('No pending registration found.');
    }

    final response = await _client.post(
      '/auth/identity',
      body: {
        'registration_token': registrationToken,
        'nickname': nickname,
        'phone': phone,
        'birthdate': birthdate,
        'gender': gender,
        'country': country,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    await _store.savePendingPhoneOtp(
      phone: data['phone'].toString(),
      otp: data['debug_phone_otp']?.toString() ?? '',
    );

    return _store.debugPhoneOtp;
  }

  @override
  Future<void> verifyPhoneOtp(String otp) async {
    final registrationToken = _store.pendingRegistrationToken;
    if (registrationToken == null) {
      throw ApiException('No pending registration found.');
    }

    final response = await _client.post(
      '/auth/phone/verify',
      body: {'registration_token': registrationToken, 'otp': otp},
    );

    final data = response['data'] as Map<String, dynamic>;
    await _store.saveAuthSession(
      token: data['token'].toString(),
      user: Map<String, dynamic>.from(data['user'] as Map),
    );
    await _store.clearPendingRegistration();
  }

  @override
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login/email',
      body: {'email': email, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    await _store.saveAuthSession(
      token: data['token'].toString(),
      user: Map<String, dynamic>.from(data['user'] as Map),
    );
  }

  @override
  Future<void> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login/phone',
      body: {'phone': phone, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    await _store.saveAuthSession(
      token: data['token'].toString(),
      user: Map<String, dynamic>.from(data['user'] as Map),
    );
  }

  @override
  Future<void> loginWithGoogle({
    required String idToken,
    String? serverAuthCode,
  }) async {
    final response = await _client.post(
      '/auth/login/google',
      body: {'id_token': idToken, 'server_auth_code': serverAuthCode},
    );

    final data = response['data'] as Map<String, dynamic>;
    await _store.saveAuthSession(
      token: data['token'].toString(),
      user: Map<String, dynamic>.from(data['user'] as Map),
    );
  }

  @override
  Future<String?> requestPasswordReset(String email) async {
    final response = await _client.post(
      '/auth/password/forgot',
      body: {'email': email},
    );

    final data = response['data'] as Map<String, dynamic>;
    final resetToken = data['debug_reset_token']?.toString();
    if (resetToken == null || resetToken.isEmpty) {
      throw ApiException('No reset token returned from server.');
    }

    await _store.savePasswordReset(
      token: resetToken,
      maskedEmail: data['email_masked']?.toString() ?? email,
      resetCode: data['debug_reset_code']?.toString(),
    );

    return _store.passwordResetCode;
  }

  @override
  Future<void> resetPassword({
    required String password,
    required String confirmPassword,
  }) async {
    final resetToken = _store.passwordResetToken;
    if (resetToken == null) {
      throw ApiException('No password reset session found.');
    }

    await _client.post(
      '/auth/password/reset',
      body: {
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': confirmPassword,
      },
    );

    await _store.clearPasswordReset();
  }
}

final class FakeAuthRepository implements AuthRepository {
  final AuthFlowStore _store = AuthFlowStore.instance;

  @override
  Future<bool> restoreSession() async => _store.hasActiveSession;

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _store.savePendingRegistration(
      registrationToken: 'test-registration-token',
      email: email,
      maskedEmail:
          'te*****@${email.contains('@') ? email.split('@').last : 'example.com'}',
      emailCode: '11111',
    );
  }

  @override
  Future<String?> resendEmailVerification() async => '11111';

  @override
  Future<void> verifyEmail() async {}

  @override
  Future<String?> completeIdentity({
    required String nickname,
    required String phone,
    required String birthdate,
    required String gender,
    required String country,
  }) async {
    await _store.savePendingPhoneOtp(phone: phone, otp: '52678');
    return '52678';
  }

  @override
  Future<void> verifyPhoneOtp(String otp) async {
    await _store.saveAuthSession(
      token: 'fake-auth-token',
      user: {
        'id': 1,
        'email': 'tester@example.com',
        'phone': '01000000000',
        'nickname': 'Tester',
      },
    );
    await _store.clearPendingRegistration();
  }

  @override
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await _store.saveAuthSession(
      token: 'fake-auth-token',
      user: {'email': email},
    );
  }

  @override
  Future<void> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    await _store.saveAuthSession(
      token: 'fake-auth-token',
      user: {'phone': phone},
    );
  }

  @override
  Future<void> loginWithGoogle({
    required String idToken,
    String? serverAuthCode,
  }) async {
    await _store.saveAuthSession(
      token: 'fake-google-auth-token',
      user: {
        'email': 'google@example.com',
        'nickname': 'Google User',
        'auth_provider': 'google',
      },
    );
  }

  @override
  Future<String?> requestPasswordReset(String email) async {
    await _store.savePasswordReset(
      token: 'fake-reset-token',
      maskedEmail: email,
      resetCode: '99999',
    );
    return '99999';
  }

  @override
  Future<void> resetPassword({
    required String password,
    required String confirmPassword,
  }) async {}
}
