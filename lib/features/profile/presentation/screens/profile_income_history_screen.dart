import 'package:flutter/material.dart';

import '../../data/profile_economy_repository.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileIncomeHistoryScreen extends StatefulWidget {
  const ProfileIncomeHistoryScreen({super.key});

  @override
  State<ProfileIncomeHistoryScreen> createState() =>
      _ProfileIncomeHistoryScreenState();
}

class _ProfileIncomeHistoryScreenState
    extends State<ProfileIncomeHistoryScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _background = Color(0xFFF4F4F4);

  static const List<String> _filters = [
    'الكل',
    'هدايا الاليف',
    'هدايا الغرف الصوتي',
    'العاب',
    'المرود',
  ];

  final ProfileEconomyRepository _economyRepository =
      ProfileEconomyRepository.instance;

  String _selectedFilter = 'الكل';
  _HistoryWalletType _selectedWalletType = _HistoryWalletType.coins;
  EconomyWalletData _wallet = const EconomyWalletData(
    coinsBalance: 0,
    diamondsBalance: 0,
  );
  List<WalletRecordData> _entries = const <WalletRecordData>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final walletType = _selectedWalletType == _HistoryWalletType.coins
        ? 'coins'
        : 'diamonds';

    try {
      final payload = await _economyRepository.loadHistory(
        walletType: walletType,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _wallet = payload.wallet;
        _entries = payload.records;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final balance = _selectedWalletType == _HistoryWalletType.coins
        ? _wallet.coinsBalance
        : _wallet.diamondsBalance;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Container(
                      color: _background,
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 22),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              label: 'profile-income-history-back',
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
                            'History',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 8, 25, 14),
                      child: Row(
                        children: [
                          Text(
                            'الدخل: $balance',
                            style: const TextStyle(
                              color: _primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _HistoryWalletToggle(
                            label: 'الماس',
                            isActive:
                                _selectedWalletType ==
                                _HistoryWalletType.diamonds,
                            semanticsLabel: 'profile-history-wallet-diamonds',
                            onTap: () {
                              setState(() {
                                _selectedWalletType =
                                    _HistoryWalletType.diamonds;
                              });
                              _loadHistory();
                            },
                          ),
                          const SizedBox(width: 18),
                          _HistoryWalletToggle(
                            label: 'الكوينز',
                            isActive:
                                _selectedWalletType == _HistoryWalletType.coins,
                            semanticsLabel: 'profile-history-wallet-coins',
                            onTap: () {
                              setState(() {
                                _selectedWalletType = _HistoryWalletType.coins;
                              });
                              _loadHistory();
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: _background,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          children: _filters.map((filter) {
                            final isActive = filter == _selectedFilter;
                            return Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Semantics(
                                label: 'profile-income-history-filter-$filter',
                                button: true,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = filter;
                                    });
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        filter,
                                        style: const TextStyle(
                                          color: _primaryBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: switch (filter) {
                                          'الكل' => 19,
                                          'هدايا الاليف' => 51,
                                          'هدايا الغرف الصوتي' => 83,
                                          'العاب' => 25,
                                          _ => 27,
                                        },
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? _primaryBlue
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: _primaryBlue,
                        onRefresh: _loadHistory,
                        child: _entries.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(
                                    height: 260,
                                    child: Center(
                                      child: Text(
                                        'لا توجد عمليات حتى الآن',
                                        style: TextStyle(
                                          color: _primaryBlue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _entries.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      height: 2,
                                      thickness: 2,
                                      color: _background,
                                    ),
                                itemBuilder: (context, index) {
                                  final entry = _entries[index];
                                  final amountPrefix =
                                      entry.direction == 'debit' ? '-' : '+';
                                  return Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      12,
                                    ),
                                    child: Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.dateLabel,
                                              style: const TextStyle(
                                                color: _primaryBlue,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              entry.timeLabel,
                                              style: const TextStyle(
                                                color: _primaryBlue,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '$amountPrefix${entry.amount}',
                                              style: const TextStyle(
                                                color: _primaryBlue,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              entry.subtitle.isEmpty
                                                  ? entry.title
                                                  : entry.subtitle,
                                              style: const TextStyle(
                                                color: _primaryBlue,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
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
    );
  }
}

class _HistoryWalletToggle extends StatelessWidget {
  const _HistoryWalletToggle({
    required this.label,
    required this.isActive,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _ProfileIncomeHistoryScreenState._primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: isActive ? (label == 'الماس' ? 42 : 41) : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: isActive
                      ? _ProfileIncomeHistoryScreenState._primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _HistoryWalletType { coins, diamonds }
