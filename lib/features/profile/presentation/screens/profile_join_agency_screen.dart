import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

class ProfileJoinAgencyScreen extends StatelessWidget {
  const ProfileJoinAgencyScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 52, 18, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الانضمام الي وكالة',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'profile-join-agency-back',
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
              ),
              const Spacer(),
              Image.asset(
                'assets/images/profile_join_agency_empty.png',
                width: 91,
                height: 91,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 20),
              const Text(
                'لا يوجد وكالة مقترحة الان !',
                style: TextStyle(
                  color: _primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                child: Semantics(
                  label: 'profile-join-agency-submit',
                  button: true,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.profileAgencyLink);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'الانضمام الي الوكالة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
