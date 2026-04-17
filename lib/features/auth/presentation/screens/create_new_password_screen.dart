import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/router/app_router.dart';
import '../../data/auth_repository.dart';
import '../widgets/numeric_keyboard.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _backCircle = Color(0xFFB4D1EF);
  static const Color _fieldBackground = Color(0xFFF9F9F9);
  static const Color _mutedText = Color(0xFF8C8C8C);

  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _activeFieldIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _appendDigit(String value) {
    final controller = _activeFieldIndex == 0
        ? _newPasswordController
        : _confirmPasswordController;

    controller.text = '${controller.text}$value';
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    setState(() {});
  }

  void _deleteDigit() {
    final controller = _activeFieldIndex == 0
        ? _newPasswordController
        : _confirmPasswordController;
    if (controller.text.isEmpty) {
      return;
    }

    controller.text = controller.text.substring(0, controller.text.length - 1);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    setState(() {});
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
                                  AppRoutes.resetPasswordRequest,
                                );
                              },
                            ),
                            SizedBox(height: height * (16 / 812)),
                            const Text(
                              'Create new password 🔒',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const Text(
                              'Create your new password . if you forget it, then\nyou have to do forgot password.',
                              style: TextStyle(
                                color: _mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: height * (50 / 812)),
                            const _FieldLabel('New Password'),
                            SizedBox(height: height * (2 / 812)),
                            _PasswordField(
                              controller: _newPasswordController,
                              isObscured: _obscureNewPassword,
                              isActive: _activeFieldIndex == 0,
                              onTap: () {
                                setState(() {
                                  _activeFieldIndex = 0;
                                });
                              },
                              onToggleVisibility: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            SizedBox(height: height * (20 / 812)),
                            const _FieldLabel('Confirm New Password'),
                            SizedBox(height: height * (2 / 812)),
                            _PasswordField(
                              controller: _confirmPasswordController,
                              isObscured: _obscureConfirmPassword,
                              isActive: _activeFieldIndex == 1,
                              onTap: () {
                                setState(() {
                                  _activeFieldIndex = 1;
                                });
                              },
                              onToggleVisibility: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            SizedBox(height: height * (30 / 812)),
                            Center(
                              child: SizedBox(
                                width: width * (290 / 375),
                                height: height * (43 / 812),
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _submitReset,
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
                                      : const Text('Save New Password'),
                                ),
                              ),
                            ),
                            SizedBox(height: height * (100 / 812)),
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

  Future<void> _submitReset() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthRepository.instance.resetPassword(
        password: _newPasswordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
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
          color: _CreateNewPasswordScreenState._backCircle,
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: _CreateNewPasswordScreenState._primaryBlue,
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
    return Text(
      label,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 2.5,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.isObscured,
    required this.isActive,
    required this.onTap,
    required this.onToggleVisibility,
  });

  final TextEditingController controller;
  final bool isObscured;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _CreateNewPasswordScreenState._fieldBackground,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: _CreateNewPasswordScreenState._primaryBlue)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/login_lock_icon.svg',
              width: 18,
              height: 18,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: IgnorePointer(
                child: TextField(
                  controller: controller,
                  obscureText: isObscured,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    color: _CreateNewPasswordScreenState._primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onToggleVisibility,
              child: SvgPicture.asset(
                'assets/images/login_eye_off_icon.svg',
                width: 18,
                height: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
