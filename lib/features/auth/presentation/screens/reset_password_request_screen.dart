import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/router/app_router.dart';
import '../../data/auth_repository.dart';

class ResetPasswordRequestScreen extends StatefulWidget {
  const ResetPasswordRequestScreen({super.key});

  @override
  State<ResetPasswordRequestScreen> createState() =>
      _ResetPasswordRequestScreenState();
}

class _ResetPasswordRequestScreenState
    extends State<ResetPasswordRequestScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _backCircle = Color(0xFFB4D1EF);
  static const Color _fieldBackground = Color(0xFFF9F9F9);
  static const Color _mutedText = Color(0xFF8C8C8C);

  late final TextEditingController _emailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'mohamedahmed958@gmail.com');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * (55 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: _BackBubbleButton(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        if (navigator.canPop()) {
                          navigator.pop();
                          return;
                        }

                        navigator.pushReplacementNamed(AppRoutes.login);
                      },
                    ),
                  ),
                  SizedBox(height: height * (16 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: const Text(
                      'Reset your password 🔑',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: const Text(
                      'Please enter your email and we will send an\nOTP code in the next step to reset your\npassword.',
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: height * (30 / 812)),
                  const _FieldLabel('Email'),
                  SizedBox(height: height * (2 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: _EmailField(controller: _emailController),
                  ),
                  SizedBox(height: height * (50 / 812)),
                  Center(
                    child: SizedBox(
                      width: width * (290 / 375),
                      height: height * (43 / 812),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
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
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Continue'),
                      ),
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

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final resetCode = await AuthRepository.instance.requestPasswordReset(
        _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (resetCode != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dev reset code: $resetCode')));
      }

      Navigator.of(context).pushNamed(AppRoutes.createNewPassword);
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
          _isSubmitting = false;
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
          color: _ResetPasswordRequestScreenState._backCircle,
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: _ResetPasswordRequestScreenState._primaryBlue,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 2.5,
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _ResetPasswordRequestScreenState._fieldBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/login_email_icon.svg',
            width: 18,
            height: 18,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              textAlign: TextAlign.center,
              cursorColor: _ResetPasswordRequestScreenState._primaryBlue,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                color: _ResetPasswordRequestScreenState._primaryBlue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
