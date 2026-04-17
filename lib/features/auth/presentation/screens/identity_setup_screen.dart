import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../data/auth_repository.dart';

class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _backCircle = Color(0xFFB4D1EF);
  static const Color _fieldBackground = Color(0xFFF9F9F9);
  static const Color _mutedText = Color(0xFF8C8C8C);

  late final TextEditingController _nicknameController;
  late final TextEditingController _numberController;
  late final TextEditingController _countryController;

  String _selectedDay = '09';
  String _selectedMonth = '20';
  String _selectedYear = '2004';
  String _selectedGender = 'Man';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: 'Mohamed Ahmed');
    _numberController = TextEditingController(text: '01017315927');
    _countryController = TextEditingController(text: 'Egypt');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _numberController.dispose();
    _countryController.dispose();
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

                        navigator.pushReplacementNamed(AppRoutes.checkEmail);
                      },
                    ),
                  ),
                  SizedBox(height: height * (16 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: const Text(
                      'Your datify identity',
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
                      'Create a unique nickname that represents you.\nIt’s how others will know and remember you.',
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: height * (15 / 812)),
                  const _SectionLabel('Nickname'),
                  SizedBox(height: height * (2 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: _CenteredTextField(
                      controller: _nicknameController,
                      keyboardType: TextInputType.name,
                    ),
                  ),
                  SizedBox(height: height * (10 / 812)),
                  const _SectionLabel('Your Number'),
                  SizedBox(height: height * (2 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: _CenteredTextField(
                      controller: _numberController,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  SizedBox(height: height * (10 / 812)),
                  const _SectionLabel('Birthdate'),
                  SizedBox(height: height * (2 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PickerBox(
                            value: _selectedDay,
                            onTap: () {
                              setState(() {
                                _selectedDay = _selectedDay == '09'
                                    ? '10'
                                    : '09';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 27),
                        Expanded(
                          child: _PickerBox(
                            value: _selectedMonth,
                            onTap: () {
                              setState(() {
                                _selectedMonth = _selectedMonth == '20'
                                    ? '21'
                                    : '20';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 27),
                        Expanded(
                          child: _PickerBox(
                            value: _selectedYear,
                            onTap: () {
                              setState(() {
                                _selectedYear = _selectedYear == '2004'
                                    ? '2005'
                                    : '2004';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height * (10 / 812)),
                  const _SectionLabel('Gender'),
                  SizedBox(height: height * (2 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _GenderOption(
                            label: 'Man',
                            isSelected: _selectedGender == 'Man',
                            onTap: () {
                              setState(() {
                                _selectedGender = 'Man';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 95),
                        Expanded(
                          child: _GenderOption(
                            label: 'Woman',
                            isSelected: _selectedGender == 'Woman',
                            onTap: () {
                              setState(() {
                                _selectedGender = 'Woman';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height * (10 / 812)),
                  const _SectionLabel('Country'),
                  SizedBox(height: height * (2 / 812)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * (18 / 375),
                    ),
                    child: _CenteredTextField(
                      controller: _countryController,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  SizedBox(height: height * (40 / 812)),
                  Center(
                    child: SizedBox(
                      width: width * (290 / 375),
                      height: height * (43 / 812),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitIdentity,
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

  Future<void> _submitIdentity() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final debugOtp = await AuthRepository.instance.completeIdentity(
        nickname: _nicknameController.text.trim(),
        phone: _numberController.text.trim(),
        birthdate: '$_selectedYear-$_selectedDay-$_selectedMonth',
        gender: _selectedGender,
        country: _countryController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (debugOtp != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dev OTP: $debugOtp')));
      }

      Navigator.of(context).pushNamed(AppRoutes.otpVerification);
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
          color: _IdentitySetupScreenState._backCircle,
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: _IdentitySetupScreenState._primaryBlue,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

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

class _CenteredTextField extends StatelessWidget {
  const _CenteredTextField({
    required this.controller,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _IdentitySetupScreenState._fieldBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        style: const TextStyle(
          color: _IdentitySetupScreenState._primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PickerBox extends StatelessWidget {
  const _PickerBox({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _IdentitySetupScreenState._fieldBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            color: _IdentitySetupScreenState._primaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _IdentitySetupScreenState._fieldBackground,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: _IdentitySetupScreenState._primaryBlue)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: _IdentitySetupScreenState._primaryBlue,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
