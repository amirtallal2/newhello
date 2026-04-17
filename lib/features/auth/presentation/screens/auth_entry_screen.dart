import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/router/app_router.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _border = Color(0xFFF4F3F4);
  static const Color _mutedText = Color(0xFF8C8C8C);
  static const Color _secondaryText = Color(0xFF626262);

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
                        color: _mutedText,
                      ),
                    ),
                  ),
                  SizedBox(height: height * (50 / 812)),
                  _AuthOptionButton(
                    width: width * (290 / 375),
                    height: height * (43 / 812),
                    iconAsset: 'assets/images/auth_google.svg',
                    label: 'Continue with Google',
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.home);
                    },
                  ),
                  SizedBox(height: height * (15 / 812)),
                  _AuthOptionButton(
                    width: width * (290 / 375),
                    height: height * (43 / 812),
                    iconAsset: 'assets/images/auth_apple.svg',
                    label: 'Continue with Apple',
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.home);
                    },
                  ),
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
                        backgroundColor: _primaryBlue,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don’t have an account? ',
                        style: TextStyle(
                          color: _secondaryText,
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
                            color: _primaryBlue,
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
}

class _AuthOptionButton extends StatelessWidget {
  const _AuthOptionButton({
    required this.width,
    required this.height,
    required this.iconAsset,
    required this.label,
    required this.onPressed,
  });

  final double width;
  final double height;
  final String iconAsset;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: AuthEntryScreen._border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          children: [
            SvgPicture.asset(iconAsset, width: 19, height: 19),
            const SizedBox(width: 40),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 2.5,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 19),
          ],
        ),
      ),
    );
  }
}
