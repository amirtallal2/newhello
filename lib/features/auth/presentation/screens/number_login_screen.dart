import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../data/auth_repository.dart';
import '../widgets/auth_credentials_screen.dart';

class NumberLoginScreen extends StatelessWidget {
  const NumberLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthCredentialsScreen(
      title: 'Welcome back 👋',
      subtitle: 'Please enter your number & password to sign in.',
      primaryFieldLabel: 'Number',
      primaryFieldHint: 'Enter Your Number',
      passwordHint: 'Enter Your Password',
      primaryFieldIconAsset: 'assets/images/login_phone_icon.svg',
      primaryKeyboardType: TextInputType.phone,
      backFallbackRoute: AppRoutes.authEntry,
      submitRoute: AppRoutes.home,
      submitTopSpacingFactor: 50 / 812,
      submitLabel: 'Log in',
      subtitleLineHeight: 2.5,
      firstFieldTopSpacingFactor: 20 / 812,
      footerPrefixText: 'Don’t have an account? ',
      footerActionText: 'Sign up',
      footerActionRoute: AppRoutes.signUp,
      inlineActionText: 'Forgot password?',
      inlineActionRoute: AppRoutes.resetPasswordRequest,
      onSubmit: (phone, password, _) {
        return AuthRepository.instance.loginWithPhone(
          phone: phone,
          password: password,
        );
      },
    );
  }
}
