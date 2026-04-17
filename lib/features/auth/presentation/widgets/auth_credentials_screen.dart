import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef AuthSubmitCallback =
    Future<void> Function(
      String primaryValue,
      String passwordValue,
      bool isChecked,
    );

class AuthCredentialsScreen extends StatefulWidget {
  const AuthCredentialsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryFieldLabel,
    required this.primaryFieldHint,
    required this.passwordHint,
    required this.primaryFieldIconAsset,
    required this.primaryKeyboardType,
    required this.backFallbackRoute,
    required this.submitRoute,
    required this.submitTopSpacingFactor,
    required this.submitLabel,
    required this.subtitleLineHeight,
    required this.firstFieldTopSpacingFactor,
    required this.footerPrefixText,
    required this.footerActionText,
    required this.footerActionRoute,
    this.inlineActionText,
    this.inlineActionRoute,
    this.checkboxPrefixText,
    this.checkboxActionText,
    this.checkboxActionRoute,
    this.onSubmit,
  });

  final String title;
  final String subtitle;
  final String primaryFieldLabel;
  final String primaryFieldHint;
  final String passwordHint;
  final String primaryFieldIconAsset;
  final TextInputType primaryKeyboardType;
  final String backFallbackRoute;
  final String submitRoute;
  final double submitTopSpacingFactor;
  final String submitLabel;
  final double subtitleLineHeight;
  final double firstFieldTopSpacingFactor;
  final String footerPrefixText;
  final String footerActionText;
  final String footerActionRoute;
  final String? inlineActionText;
  final String? inlineActionRoute;
  final String? checkboxPrefixText;
  final String? checkboxActionText;
  final String? checkboxActionRoute;
  final AuthSubmitCallback? onSubmit;

  static const Color primaryBlue = Color(0xFF285F98);
  static const Color fieldBackground = Color(0xFFF9F9F9);
  static const Color mutedText = Color(0xFF8C8C8C);
  static const Color hintText = Color(0xFFABABAB);
  static const Color secondaryText = Color(0xFF626262);
  static const Color divider = Color(0xFFF3F3F3);
  static const Color backCircle = Color(0xFFB4D1EF);

  @override
  State<AuthCredentialsScreen> createState() => _AuthCredentialsScreenState();
}

class _AuthCredentialsScreenState extends State<AuthCredentialsScreen> {
  bool _isChecked = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  late final TextEditingController _primaryController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _primaryController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _passwordController.dispose();
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

                        navigator.pushReplacementNamed(
                          widget.backFallbackRoute,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: height * (16 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: AuthCredentialsScreen.primaryBlue,
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
                    child: Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: AuthCredentialsScreen.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: widget.subtitleLineHeight,
                      ),
                    ),
                  ),
                  SizedBox(height: height * widget.firstFieldTopSpacingFactor),
                  _FieldLabel(widget.primaryFieldLabel),
                  SizedBox(height: height * (2 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: _AuthInputField(
                      hint: widget.primaryFieldHint,
                      leadingAsset: widget.primaryFieldIconAsset,
                      keyboardType: widget.primaryKeyboardType,
                      textInputAction: TextInputAction.next,
                      controller: _primaryController,
                    ),
                  ),
                  SizedBox(height: height * (10 / 812)),
                  const _FieldLabel('Password'),
                  SizedBox(height: height * (2 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: _AuthInputField(
                      hint: widget.passwordHint,
                      leadingAsset: 'assets/images/login_lock_icon.svg',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      trailing: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: SvgPicture.asset(
                            'assets/images/login_eye_off_icon.svg',
                            width: 18,
                            height: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * (6 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: _InlineOptionsRow(
                      isChecked: _isChecked,
                      checkboxPrefixText: widget.checkboxPrefixText,
                      checkboxActionText: widget.checkboxActionText,
                      onToggleChecked: () {
                        setState(() {
                          _isChecked = !_isChecked;
                        });
                      },
                      onTapCheckboxAction: widget.checkboxActionRoute == null
                          ? null
                          : () {
                              Navigator.of(
                                context,
                              ).pushNamed(widget.checkboxActionRoute!);
                            },
                      inlineActionText: widget.inlineActionText,
                      onTapInlineAction: widget.inlineActionRoute == null
                          ? null
                          : () {
                              Navigator.of(
                                context,
                              ).pushNamed(widget.inlineActionRoute!);
                            },
                    ),
                  ),
                  SizedBox(height: height * (18 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: const Divider(
                      height: 1,
                      thickness: 1,
                      color: AuthCredentialsScreen.divider,
                    ),
                  ),
                  SizedBox(height: height * (5 / 812)),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.footerPrefixText,
                          style: const TextStyle(
                            color: AuthCredentialsScreen.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 2.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed(widget.footerActionRoute);
                          },
                          child: Text(
                            widget.footerActionText,
                            style: const TextStyle(
                              color: AuthCredentialsScreen.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 2.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height * widget.submitTopSpacingFactor),
                  Center(
                    child: SizedBox(
                      width: width * (290 / 375),
                      height: height * (43 / 812),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AuthCredentialsScreen.primaryBlue,
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
                            : Text(widget.submitLabel),
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

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final primaryValue = _primaryController.text.trim();
    final passwordValue = _passwordController.text.trim();

    if (primaryValue.isEmpty || passwordValue.isEmpty) {
      _showMessage('Please fill in all required fields.');
      return;
    }

    if (widget.checkboxPrefixText != null && !_isChecked) {
      _showMessage('You need to accept the required policy first.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(primaryValue, passwordValue, _isChecked);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamed(widget.submitRoute);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          color: AuthCredentialsScreen.backCircle,
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: AuthCredentialsScreen.primaryBlue,
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

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.hint,
    required this.leadingAsset,
    required this.controller,
    required this.textInputAction,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
  });

  final String hint;
  final String leadingAsset;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AuthCredentialsScreen.fieldBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SvgPicture.asset(leadingAsset, width: 18, height: 18),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              obscuringCharacter: '•',
              cursorColor: AuthCredentialsScreen.primaryBlue,
              decoration:
                  const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '',
                  ).copyWith(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: AuthCredentialsScreen.hintText,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 3,
                    ),
                  ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 3,
              ),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _InlineOptionsRow extends StatelessWidget {
  const _InlineOptionsRow({
    required this.isChecked,
    required this.onToggleChecked,
    this.checkboxPrefixText,
    this.checkboxActionText,
    this.onTapCheckboxAction,
    this.inlineActionText,
    this.onTapInlineAction,
  });

  final bool isChecked;
  final VoidCallback onToggleChecked;
  final String? checkboxPrefixText;
  final String? checkboxActionText;
  final VoidCallback? onTapCheckboxAction;
  final String? inlineActionText;
  final VoidCallback? onTapInlineAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onToggleChecked,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              _CheckboxBox(isSelected: isChecked),
              const SizedBox(width: 10),
              if (checkboxPrefixText != null || checkboxActionText != null)
                _AgreementText(
                  prefixText: checkboxPrefixText ?? '',
                  actionText: checkboxActionText ?? '',
                  onTapAction: onTapCheckboxAction,
                )
              else
                const Text(
                  'Remember me',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    height: 3.75,
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        if (inlineActionText != null)
          TextButton(
            onPressed: onTapInlineAction,
            style: TextButton.styleFrom(
              foregroundColor: AuthCredentialsScreen.primaryBlue,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              inlineActionText!,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                height: 3.75,
              ),
            ),
          ),
      ],
    );
  }
}

class _AgreementText extends StatelessWidget {
  const _AgreementText({
    required this.prefixText,
    required this.actionText,
    this.onTapAction,
  });

  final String prefixText;
  final String actionText;
  final VoidCallback? onTapAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      children: [
        Text(
          prefixText,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 8,
            fontWeight: FontWeight.w500,
            height: 3.75,
          ),
        ),
        GestureDetector(
          onTap: onTapAction,
          child: Text(
            actionText,
            style: const TextStyle(
              color: AuthCredentialsScreen.primaryBlue,
              fontSize: 8,
              fontWeight: FontWeight.w500,
              height: 3.75,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckboxBox extends StatelessWidget {
  const _CheckboxBox({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isSelected
            ? AuthCredentialsScreen.primaryBlue
            : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: AuthCredentialsScreen.primaryBlue,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 10, color: Colors.white)
          : null,
    );
  }
}
