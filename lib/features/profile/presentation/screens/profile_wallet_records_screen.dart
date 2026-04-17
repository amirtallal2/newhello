import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileWalletRecordsScreen extends StatelessWidget {
  const ProfileWalletRecordsScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);
  static const Color _successGreen = Color(0xFF34A853);
  static const Color _errorRed = Color(0xFFEA4335);

  static const List<_WalletRecordItemData> _records = [
    _WalletRecordItemData(isSuccess: true),
    _WalletRecordItemData(isSuccess: true),
    _WalletRecordItemData(isSuccess: false),
    _WalletRecordItemData(isSuccess: true),
    _WalletRecordItemData(isSuccess: false),
    _WalletRecordItemData(isSuccess: false),
    _WalletRecordItemData(isSuccess: true),
  ];

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
              Container(
                color: _surfaceGrey,
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 35),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        label: 'profile-wallet-records-back',
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
                    ),
                    const Text(
                      'تسجيل',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(
                          children: const [
                            Text(
                              'عدد العملات المتاحة الان : 500',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Text(
                              'تحويل المبلغ',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        height: 40,
                        color: _surfaceGrey,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'الكل',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: 19,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _primaryBlue,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                                child: SizedBox(height: 2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 2,
                        thickness: 2,
                        color: _surfaceGrey,
                      ),
                      ..._records.map(
                        (record) => _WalletRecordRow(data: record),
                      ),
                    ],
                  ),
                ),
              ),
              const MainBottomNavigation(
                currentTab: MainBottomNavigationTab.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletRecordRow extends StatelessWidget {
  const _WalletRecordRow({required this.data});

  final _WalletRecordItemData data;

  @override
  Widget build(BuildContext context) {
    final accentColor = data.isSuccess
        ? ProfileWalletRecordsScreen._successGreen
        : ProfileWalletRecordsScreen._errorRed;
    final statusText = data.isSuccess ? 'تم الشحن بنجاح' : 'تم الغاء العملية';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ProfileWalletRecordsScreen._surfaceGrey,
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '20/10/2024',
                style: TextStyle(
                  color: ProfileWalletRecordsScreen._primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '10:55',
                style: TextStyle(
                  color: ProfileWalletRecordsScreen._primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+200',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'شحن 200 عملة الان',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletRecordItemData {
  const _WalletRecordItemData({required this.isSuccess});

  final bool isSuccess;
}
