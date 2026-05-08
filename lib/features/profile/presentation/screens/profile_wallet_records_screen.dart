import 'package:flutter/material.dart';

import '../../data/profile_economy_repository.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileWalletRecordsScreen extends StatefulWidget {
  const ProfileWalletRecordsScreen({super.key});

  @override
  State<ProfileWalletRecordsScreen> createState() =>
      _ProfileWalletRecordsScreenState();
}

class _ProfileWalletRecordsScreenState
    extends State<ProfileWalletRecordsScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);
  static const Color _successGreen = Color(0xFF34A853);
  static const Color _errorRed = Color(0xFFEA4335);

  final ProfileEconomyRepository _economyRepository =
      ProfileEconomyRepository.instance;

  EconomyWalletData _wallet = const EconomyWalletData(
    coinsBalance: 500,
    diamondsBalance: 5,
  );
  List<WalletRecordData> _records = const <WalletRecordData>[];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final payload = await _economyRepository.loadWalletRecords();
      if (!mounted) {
        return;
      }
      setState(() {
        _wallet = payload.wallet;
        _records = payload.records;
      });
    } catch (_) {}
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
                child: RefreshIndicator(
                  color: _primaryBlue,
                  onRefresh: _loadRecords,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Row(
                            children: [
                              Text(
                                'عدد العملات المتاحة الان : ${_wallet.coinsBalance}',
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
                        if (_records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'لا توجد عمليات حتى الآن',
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          ..._records.map(
                            (record) => _WalletRecordRow(data: record),
                          ),
                      ],
                    ),
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

  final WalletRecordData data;

  @override
  Widget build(BuildContext context) {
    final accentColor = data.isSuccess
        ? _ProfileWalletRecordsScreenState._successGreen
        : _ProfileWalletRecordsScreenState._errorRed;
    final amountPrefix = data.direction == 'debit' ? '-' : '+';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _ProfileWalletRecordsScreenState._surfaceGrey,
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.dateLabel,
                style: TextStyle(
                  color: _ProfileWalletRecordsScreenState._primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                data.timeLabel,
                style: TextStyle(
                  color: _ProfileWalletRecordsScreenState._primaryBlue,
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
                data.title,
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
                '$amountPrefix${data.amount}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data.subtitle,
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
