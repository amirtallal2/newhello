import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../data/auth_repository.dart';
import '../widgets/auth_credentials_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthCredentialsScreen(
      title: 'Create an account 👩‍💻',
      subtitle:
          'Create your account in seconds. We’ll help you\nfind your perfect match.',
      primaryFieldLabel: 'Email',
      primaryFieldHint: 'Email',
      passwordHint: 'Password',
      primaryFieldIconAsset: 'assets/images/login_email_icon.svg',
      primaryKeyboardType: TextInputType.emailAddress,
      backFallbackRoute: AppRoutes.authEntry,
      submitRoute: AppRoutes.checkEmail,
      submitTopSpacingFactor: 212 / 812,
      submitLabel: 'Sign up',
      subtitleLineHeight: 1.25,
      firstFieldTopSpacingFactor: 15 / 812,
      footerPrefixText: 'Already have an account? ',
      footerActionText: 'Sign in',
      footerActionRoute: AppRoutes.login,
      checkboxPrefixText: 'I agree to Soul ',
      checkboxActionText: 'Privacy Policy.',
      checkboxActionRoute: AppRoutes.bootstrap,
      onSubmit: (email, password, _) {
        return AuthRepository.instance.signUp(email: email, password: password);
      },
    );
  }
}
