import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../data/auth_repository.dart';
import '../widgets/numeric_keyboard.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _backCircle = Color(0xFFB4D1EF);
  static const Color _fieldBackground = Color(0xFFF9F9F9);
  static const Color _mutedText = Color(0xFF8C8C8C);

  final List<String> _digits = ['5', '2', '6', '', ''];
  bool _isSubmitting = false;

  int get _activeIndex {
    final index = _digits.indexOf('');
    return index == -1 ? _digits.length - 1 : index;
  }

  void _appendDigit(String value) {
    final index = _digits.indexOf('');
    if (index == -1) {
      return;
    }

    setState(() {
      _digits[index] = value;
    });
  }

  void _deleteDigit() {
    final filledIndex = _digits.lastIndexWhere((digit) => digit.isNotEmpty);
    if (filledIndex == -1) {
      return;
    }

    setState(() {
      _digits[filledIndex] = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * (18 / 375),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: height * (55 / 812)),
                            _BackBubbleButton(
                              onPressed: () {
                                final navigator = Navigator.of(context);
                                if (navigator.canPop()) {
                                  navigator.pop();
                                  return;
                                }

                                navigator.pushReplacementNamed(
                                  AppRoutes.identitySetup,
                                );
                              },
                            ),
                            SizedBox(height: height * (16 / 812)),
                            const Text(
                              'OTP code verification 🔐',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const Text(
                              'We have sendan OTP code to your phone\nand +201017315927. Enter the OTP\ncode below to verify.',
                              style: TextStyle(
                                color: _mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: height * (45 / 812)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                _digits.length,
                                (index) => _OtpBox(
                                  value: _digits[index],
                                  isActive: index == _activeIndex,
                                ),
                              ),
                            ),
                            SizedBox(height: height * (50 / 812)),
                            Center(
                              child: SizedBox(
                                width: width * (290 / 375),
                                height: height * (43 / 812),
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitOtp,
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
                            SizedBox(height: height * (21 / 812)),
                            const Center(
                              child: Text(
                                'Didn’t receive phone?',
                                style: TextStyle(
                                  color: _mutedText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    color: _mutedText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                    fontFamily: 'Rubik',
                                  ),
                                  children: [
                                    TextSpan(text: 'Your can resend code in '),
                                    TextSpan(
                                      text: '50',
                                      style: TextStyle(color: _primaryBlue),
                                    ),
                                    TextSpan(text: ' s'),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: height * (110 / 812)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                NumericKeyboard(
                  onDigitPressed: _appendDigit,
                  onDeletePressed: _deleteDigit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitOtp() async {
    final usesFakeRepository = AuthRepository.instance is FakeAuthRepository;
    final otp = usesFakeRepository ? '52678' : _digits.join();

    if (!usesFakeRepository && _digits.any((digit) => digit.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full OTP code.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthRepository.instance.verifyPhoneOtp(otp);
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
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
          color: _OtpVerificationScreenState._backCircle,
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: _OtpVerificationScreenState._primaryBlue,
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.value, required this.isActive});

  final String value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _OtpVerificationScreenState._fieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: _OtpVerificationScreenState._primaryBlue)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          color: _OtpVerificationScreenState._primaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }
}
