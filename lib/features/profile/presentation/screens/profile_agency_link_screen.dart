import 'package:flutter/material.dart';

class ProfileAgencyLinkScreen extends StatefulWidget {
  const ProfileAgencyLinkScreen({super.key});

  @override
  State<ProfileAgencyLinkScreen> createState() =>
      _ProfileAgencyLinkScreenState();
}

class _ProfileAgencyLinkScreenState extends State<ProfileAgencyLinkScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceBorder = Color(0xFFE0E2E9);
  static const Color _hintGrey = Color(0xFFB7B7B7);

  static const List<String> _agencyTypes = ['لايف', 'صوتي', 'شات', 'لايف وشات'];

  final TextEditingController _invitationCodeController = TextEditingController(
    text: '51112164844',
  );

  String _selectedAgencyType = 'لايف-صوتي-شات-لايف وشات';

  @override
  void dispose() {
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _showAgencyTypePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                    'الرجاء اختيار نوع الوكالة',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ..._agencyTypes.map(
                  (agencyType) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      agencyType,
                      style: const TextStyle(
                        color: _primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(agencyType);
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
        _selectedAgencyType = selected;
      });
    }
  }

  void _submitLinkRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم ارسال طلب ربط الوكالة'),
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
                        'ربط الوكالة',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'profile-agency-link-back',
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
                const SizedBox(height: 30),
                const _AgencyLinkSectionLabel(
                  title: 'يرجي كتابة رمز دعوة الوكالة',
                  subtitle: 'الرجاء ادخال رمز الدعوة',
                ),
                const SizedBox(height: 5),
                _AgencyLinkInputShell(
                  child: TextField(
                    key: const ValueKey('profile-agency-link-invitation-code'),
                    controller: _invitationCodeController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _AgencyLinkSectionLabel(
                  title: 'الرجاء اختيار نوع الوكالة',
                  subtitle: 'يرجي كتابة نوع الوكالة التي تريد الانضمام اليها',
                ),
                const SizedBox(height: 5),
                Semantics(
                  label: 'profile-agency-link-type-field',
                  button: true,
                  child: InkWell(
                    key: const ValueKey('profile-agency-link-type-field'),
                    onTap: _showAgencyTypePicker,
                    borderRadius: BorderRadius.circular(10),
                    child: _AgencyLinkInputShell(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: _primaryBlue,
                          ),
                          const Spacer(),
                          Text(
                            _selectedAgencyType,
                            style: TextStyle(
                              color: _agencyTypes.contains(_selectedAgencyType)
                                  ? _primaryBlue
                                  : _hintGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                Semantics(
                  label: 'profile-agency-link-submit',
                  button: true,
                  child: InkWell(
                    onTap: _submitLinkRequest,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'ربط الان',
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

class _AgencyLinkSectionLabel extends StatelessWidget {
  const _AgencyLinkSectionLabel({required this.title, required this.subtitle});

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
            color: _ProfileAgencyLinkScreenState._hintGrey,
            fontSize: 7,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AgencyLinkInputShell extends StatelessWidget {
  const _AgencyLinkInputShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ProfileAgencyLinkScreenState._surfaceBorder),
      ),
      child: child,
    );
  }
}
