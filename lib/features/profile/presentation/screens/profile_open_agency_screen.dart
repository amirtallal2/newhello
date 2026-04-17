import 'package:flutter/material.dart';

class ProfileOpenAgencyScreen extends StatefulWidget {
  const ProfileOpenAgencyScreen({super.key});

  @override
  State<ProfileOpenAgencyScreen> createState() =>
      _ProfileOpenAgencyScreenState();
}

class _ProfileOpenAgencyScreenState extends State<ProfileOpenAgencyScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceBorder = Color(0xFFE0E2E9);
  static const Color _hintGrey = Color(0xFFB7B7B7);
  static const Color _avatarBlue = Color(0xFFA2BFEA);
  static const Color _softBlue = Color(0xFFCEE1FF);
  static const Color _cameraCircle = Color(0xFFB4D1EF);

  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedCountry = '';
  bool _avatarEdited = false;
  bool _frontIdUploaded = false;
  bool _backIdUploaded = false;

  @override
  void dispose() {
    _agencyNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _showCountryPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const countries = ['مصر', 'السعودية', 'الإمارات', 'الأردن'];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'اختر الدولة الخاصة بك',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ...countries.map(
                  (country) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      country,
                      style: const TextStyle(
                        color: _primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(country);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCountry = selected;
      });
    }
  }

  void _submitReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم ارسال المراجعة بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 52, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'فتح وكالة جديدة',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'profile-open-agency-back',
                      button: true,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          width: 38,
                          height: 37,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB4D1EF),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: _primaryBlue,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _avatarBlue,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person,
                          size: 44,
                          color: _avatarEdited ? Colors.white : _primaryBlue,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Semantics(
                          label: 'profile-open-agency-avatar-edit',
                          button: true,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _avatarEdited = !_avatarEdited;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: _softBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 12,
                                color: _primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel(
                  title: 'اسم الوكالة والدولة الخاصة بك',
                  subtitle: 'لا يمكن التعديل عليه بمجرد انشائه',
                ),
                const SizedBox(height: 5),
                _InputShell(
                  child: TextField(
                    key: const ValueKey('profile-open-agency-name'),
                    controller: _agencyNameController,
                    maxLength: 20,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: 'لآ يتجاوز عن 20 حرف',
                      hintStyle: TextStyle(
                        color: _hintGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: 'profile-open-agency-country-field',
                  button: true,
                  child: InkWell(
                    key: const ValueKey('profile-open-agency-country-field'),
                    onTap: _showCountryPicker,
                    borderRadius: BorderRadius.circular(10),
                    child: _InputShell(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: _primaryBlue,
                          ),
                          const Spacer(),
                          Text(
                            _selectedCountry.isEmpty
                                ? 'اختر الدولة الخاصة بك'
                                : _selectedCountry,
                            style: TextStyle(
                              color: _selectedCountry.isEmpty
                                  ? _hintGrey
                                  : _primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionLabel(
                  title: 'الهاتف والعنوان الخاص بك',
                  subtitle: 'يرجي كتابة معلوماتك الصحيحة للتحقق منها بشكل صحيح',
                ),
                const SizedBox(height: 5),
                _InputShell(
                  child: TextField(
                    key: const ValueKey('profile-open-agency-phone'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: 'رقم الهاتف الخاص بك',
                      hintStyle: TextStyle(
                        color: _hintGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _InputShell(
                  child: TextField(
                    key: const ValueKey('profile-open-agency-address'),
                    controller: _addressController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: 'العنوان الخاص بك',
                      hintStyle: TextStyle(
                        color: _hintGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionLabel(
                  title: 'معلومات الهوية',
                  subtitle: 'يرجي تحميل معلومات حقيقية وصحيحة',
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: _IdentityUploadCard(
                        label: 'بطاقة الهوية الامامية',
                        isUploaded: _frontIdUploaded,
                        semanticsLabel: 'profile-open-agency-upload-front',
                        onTap: () {
                          setState(() {
                            _frontIdUploaded = !_frontIdUploaded;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _IdentityUploadCard(
                        label: 'بطاقة الهوية الخلفية',
                        isUploaded: _backIdUploaded,
                        semanticsLabel: 'profile-open-agency-upload-back',
                        onTap: () {
                          setState(() {
                            _backIdUploaded = !_backIdUploaded;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Semantics(
                  label: 'profile-open-agency-submit',
                  button: true,
                  child: InkWell(
                    onTap: _submitReview,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'ارسال المراجعة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: _ProfileOpenAgencyScreenState._hintGrey,
            fontSize: 7,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InputShell extends StatelessWidget {
  const _InputShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ProfileOpenAgencyScreenState._surfaceBorder),
      ),
      child: child,
    );
  }
}

class _IdentityUploadCard extends StatelessWidget {
  const _IdentityUploadCard({
    required this.label,
    required this.isUploaded,
    required this.onTap,
    required this.semanticsLabel,
  });

  final String label;
  final bool isUploaded;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ProfileOpenAgencyScreenState._surfaceBorder),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: semanticsLabel,
                  button: true,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: _ProfileOpenAgencyScreenState._cameraCircle,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isUploaded ? Icons.check_rounded : Icons.camera_alt,
                        size: 18,
                        color: _ProfileOpenAgencyScreenState._primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: _ProfileOpenAgencyScreenState._primaryBlue,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
