import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../data/auth_repository.dart';
import '../widgets/auth_credentials_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthCredentialsScreen(
      title: 'Welcome back 👋',
      subtitle: 'Please enter your email & password to sign in.',
      primaryFieldLabel: 'Email',
      primaryFieldHint: 'Email',
      passwordHint: 'Password',
      primaryFieldIconAsset: 'assets/images/login_email_icon.svg',
      primaryKeyboardType: TextInputType.emailAddress,
      backFallbackRoute: AppRoutes.authEntry,
      submitRoute: AppRoutes.home,
      submitTopSpacingFactor: 212 / 812,
      submitLabel: 'Log in',
      subtitleLineHeight: 2.5,
      firstFieldTopSpacingFactor: 20 / 812,
      footerPrefixText: 'Don’t have an account? ',
      footerActionText: 'Sign up',
      footerActionRoute: AppRoutes.signUp,
      inlineActionText: 'Forgot password?',
      inlineActionRoute: AppRoutes.resetPasswordRequest,
      onSubmit: (email, password, _) {
        return AuthRepository.instance.loginWithEmail(
          email: email,
          password: password,
        );
      },
    );
  }
}
