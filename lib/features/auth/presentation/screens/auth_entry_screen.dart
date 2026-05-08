import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/config/social_auth_config.dart';
import '../../data/auth_repository.dart';
import '../../data/google_auth_service.dart';

class AuthEntryScreen extends StatefulWidget {
  const AuthEntryScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _border = Color(0xFFF4F3F4);
  static const Color _mutedText = Color(0xFF8C8C8C);
  static const Color _secondaryText = Color(0xFF626262);

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  bool _isGoogleSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Column(
                children: [
                  SizedBox(height: height * (291 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (84 / 375),
                    ),
                    child: const Text(
                      'Let’s dive into your account!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 2,
                        color: AuthEntryScreen._mutedText,
                      ),
                    ),
                  ),
                  SizedBox(height: height * (50 / 812)),
                  _AuthOptionButton(
                    width: width * (290 / 375),
                    height: height * (43 / 812),
                    iconAsset: 'assets/images/auth_google.svg',
                    label: 'Continue with Google',
                    isLoading: _isGoogleSubmitting,
                    onPressed: _signInWithGoogle,
                  ),
                  if (SocialAuthConfig.showAppleSignIn) ...[
                    SizedBox(height: height * (15 / 812)),
                    _AuthOptionButton(
                      width: width * (290 / 375),
                      height: height * (43 / 812),
                      iconAsset: 'assets/images/auth_apple.svg',
                      label: 'Continue with Apple',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Apple sign-in is not configured yet.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  SizedBox(height: height * (14 / 812)),
                  _AuthOptionButton(
                    width: width * (290 / 375),
                    height: height * (43 / 812),
                    iconAsset: 'assets/images/auth_phone.svg',
                    label: 'Continue with Number',
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.numberLogin);
                    },
                  ),
                  SizedBox(height: height * (50 / 812)),
                  SizedBox(
                    width: width * (290 / 375),
                    height: height * (43 / 812),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AuthEntryScreen._primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 2.5,
                        ),
                      ),
                      child: const Text('Log in'),
                    ),
                  ),
                  SizedBox(height: height * (20 / 812)),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Don’t have an account? ',
                        style: TextStyle(
                          color: AuthEntryScreen._secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 2.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.signUp);
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: AuthEntryScreen._primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * (110 / 812)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isGoogleSubmitting = true;
    });

    try {
      final GoogleAuthSession session = await GoogleAuthService.instance
          .signIn();
      await AuthRepository.instance.loginWithGoogle(idToken: session.idToken);

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSubmitting = false;
        });
      }
    }
  }
}

class _AuthOptionButton extends StatelessWidget {
  const _AuthOptionButton({
    required this.width,
    required this.height,
    required this.iconAsset,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final double width;
  final double height;
  final String iconAsset;
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: AuthEntryScreen._border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: isLoading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : SvgPicture.asset(iconAsset, width: 19, height: 19),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 2.5,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
