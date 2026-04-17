import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/router/app_router.dart';
import '../../data/auth_flow_store.dart';
import '../../data/auth_repository.dart';

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _backCircle = Color(0xFFB4D1EF);
  static const Color _circleBorder = Color(0xFFF1EFEF);
  static const Color _mutedText = Color(0xFF8C8C8C);

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  bool _isBusy = false;

  String get _maskedEmail =>
      AuthFlowStore.instance.pendingMaskedEmail ??
      '*********ahmed958@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: height * (55 / 812)),
                  Padding(
                    padding: EdgeInsets.only(left: width * (18 / 375)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _BackBubbleButton(
                        onPressed: () {
                          final navigator = Navigator.of(context);
                          if (navigator.canPop()) {
                            navigator.pop();
                            return;
                          }

                          navigator.pushReplacementNamed(AppRoutes.signUp);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: height * (108 / 812)),
                  Container(
                    width: width * (116 / 375),
                    height: width * (116 / 375),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CheckEmailScreen._circleBorder,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/images/login_email_icon.svg',
                      width: width * (50 / 375),
                      height: width * (50 / 375),
                    ),
                  ),
                  SizedBox(height: height * (20 / 812)),
                  const Text(
                    'Check Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CheckEmailScreen._primaryBlue,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: height * (10 / 812)),
                  SizedBox(
                    width: 240,
                    child: Text(
                      'We have sent an email to\n$_maskedEmail.\nClick the link inside to get started.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CheckEmailScreen._mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: height * (15 / 812)),
                  TextButton(
                    onPressed: _isBusy ? null : _resendEmail,
                    style: TextButton.styleFrom(
                      foregroundColor: CheckEmailScreen._primaryBlue,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Resend email',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: height * (218 / 812)),
                  SizedBox(
                    width: width * (290 / 375),
                    height: height * (43 / 812),
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _verifyEmailAndContinue,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: CheckEmailScreen._primaryBlue,
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
                      child: _isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('I’ve verified my email'),
                    ),
                  ),
                  SizedBox(height: height * (100 / 812)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isBusy = true;
    });

    try {
      final debugCode = await AuthRepository.instance.resendEmailVerification();
      if (!mounted) {
        return;
      }

      final message = debugCode == null
          ? 'Verification email resent.'
          : 'Verification email resent. Dev code: $debugCode';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _verifyEmailAndContinue() async {
    setState(() {
      _isBusy = true;
    });

    try {
      await AuthRepository.instance.verifyEmail();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(AppRoutes.identitySetup);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }
}

class _BackBubbleButton extends StatelessWidget {
  const _BackBubbleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: 38,
        height: 37,
        decoration: BoxDecoration(
          color: CheckEmailScreen._backCircle,
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: CheckEmailScreen._primaryBlue,
        ),
      ),
    );
  }
}
