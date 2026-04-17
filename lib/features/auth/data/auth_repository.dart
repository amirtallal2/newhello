import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'auth_flow_store.dart';

abstract class AuthRepository {
  static AuthRepository instance = LiveAuthRepository();

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
  Future<void> signUp({required String email, required String password}) async {
    final response = await _client.post(
      '/auth/register',
      body: {'email': email, 'password': password},
    );

    final data = response['data'] as Map<String, dynamic>;
    _store.savePendingRegistration(
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
    _store.savePendingPhoneOtp(
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
    _store.saveAuthSession(
      token: data['token'].toString(),
      user: Map<String, dynamic>.from(data['user'] as Map),
    );
    _store.clearPendingRegistration();
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
    _store.saveAuthSession(
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
    _store.saveAuthSession(
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

    _store.savePasswordReset(
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

    _store.clearPasswordReset();
  }
}

final class FakeAuthRepository implements AuthRepository {
  final AuthFlowStore _store = AuthFlowStore.instance;

  @override
  Future<void> signUp({required String email, required String password}) async {
    _store.savePendingRegistration(
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
    _store.savePendingPhoneOtp(phone: phone, otp: '52678');
    return '52678';
  }

  @override
  Future<void> verifyPhoneOtp(String otp) async {
    _store.saveAuthSession(
      token: 'fake-auth-token',
      user: {
        'id': 1,
        'email': 'tester@example.com',
        'phone': '01000000000',
        'nickname': 'Tester',
      },
    );
    _store.clearPendingRegistration();
  }

  @override
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _store.saveAuthSession(token: 'fake-auth-token', user: {'email': email});
  }

  @override
  Future<void> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    _store.saveAuthSession(token: 'fake-auth-token', user: {'phone': phone});
  }

  @override
  Future<String?> requestPasswordReset(String email) async {
    _store.savePasswordReset(
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
