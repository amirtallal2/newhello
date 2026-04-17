import 'package:flutter/material.dart';

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

  String _selectedFilter = 'الكل';
  _HistoryWalletType _selectedWalletType = _HistoryWalletType.coins;

  List<_HistoryEntry> get _entries {
    final entryTitle = _selectedWalletType == _HistoryWalletType.coins
        ? 'تبادل الحبوب الي كوينز'
        : 'تبادل الحبوب الي الماس';

    return List<_HistoryEntry>.generate(
      7,
      (_) => _HistoryEntry(amount: '+200', title: entryTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          const Text(
                            'الدخل: 2548',
                            style: TextStyle(
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
                      child: ListView.separated(
                        itemCount: _entries.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 2,
                          thickness: 2,
                          color: _background,
                        ),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '20/10/2024',
                                      style: TextStyle(
                                        color: _primaryBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '10:55',
                                      style: TextStyle(
                                        color: _primaryBlue,
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
                                      entry.amount,
                                      style: const TextStyle(
                                        color: _primaryBlue,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      entry.title,
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

class _HistoryEntry {
  const _HistoryEntry({required this.amount, required this.title});

  final String amount;
  final String title;
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
