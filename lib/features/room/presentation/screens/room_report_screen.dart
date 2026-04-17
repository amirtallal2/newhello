import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class RoomReportScreen extends StatelessWidget {
  const RoomReportScreen({super.key});

  static const List<String> _reasons = [
    'خطاب الكراهية',
    'عنف',
    'العري او النشاط الجنسي',
    'التنمر  او التحرش',
    'احتيال',
    'رسائل الكترونية مزعجة',
    'الابلاغ عن ملف تعريف الغرفة',
    'حفلة تسجيل الدخول في الغرفة',
    'محادثة غرفة التقرير',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomNavigation(
        currentTab: MainBottomNavigationTab.home,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 52),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: 'room-report-back',
                      button: true,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB4D1EF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF285F98),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'ابلاغ',
                    style: TextStyle(
                      color: Color(0xFF285F98),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'لماذا تريد الابلغ عن هذه الغرفة؟',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF285F98),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _reasons.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFD9D9D9),
                ),
                itemBuilder: (context, index) {
                  final reason = _reasons[index];

                  return Semantics(
                    label: 'room-report-reason-$index',
                    button: true,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                      },
                      child: SizedBox(
                        height: 55,
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF285F98),
                                size: 16,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    reason,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
