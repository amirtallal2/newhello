import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

class ProfileWalletScreen extends StatefulWidget {
  const ProfileWalletScreen({super.key});

  @override
  State<ProfileWalletScreen> createState() => _ProfileWalletScreenState();
}

enum _WalletTab { diamonds, coins }

class _ProfileWalletScreenState extends State<ProfileWalletScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _diamondsHeader = Color(0xFFE5B565);
  static const Color _diamondsTab = Color(0xFFFDE383);
  static const Color _diamondsPackage = Color(0xFFF4CF92);
  static const Color _diamondsPrice = Color(0xFFFDC25F);
  static const Color _coinsHeader = Color(0xFFFEE268);
  static const Color _coinsPackage = Color(0xFFFEE268);
  static const Color _coinsPrice = Color(0xFFE88102);
  static const Color _accentRed = Color(0xFFEA4335);
  static const Color _inactiveTabText = Color(0xFFF4D092);

  static const List<_WalletPackageData> _diamondPackages = [
    _WalletPackageData(
      amount: '30990',
      footerLabel: '2,894,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
    ),
    _WalletPackageData(
      amount: '6090',
      footerLabel: '578,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
    ),
    _WalletPackageData(
      amount: '600',
      footerLabel: '57,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
      bonus: '+300',
    ),
    _WalletPackageData(
      amount: '122990',
      footerLabel: '11,536,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
      bonus: '+1000',
    ),
    _WalletPackageData(
      amount: '61990',
      footerLabel: '5,736,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
    ),
  ];

  static const List<_WalletPackageData> _coinPackages = [
    _WalletPackageData(
      amount: '5000',
      footerLabel: '500',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      amount: '1000',
      footerLabel: '100',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      amount: '100',
      footerLabel: '10',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      amount: '5000000',
      footerLabel: '500000',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      amount: '100000',
      footerLabel: '10000',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      amount: '10000',
      footerLabel: '1000',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
  ];

  _WalletTab _selectedTab = _WalletTab.diamonds;

  @override
  Widget build(BuildContext context) {
    final isDiamonds = _selectedTab == _WalletTab.diamonds;
    final config = isDiamonds
        ? const _WalletViewConfig(
            headerColor: _diamondsHeader,
            packageColor: _diamondsPackage,
            footerColor: _diamondsPrice,
            activeSegmentColor: _diamondsTab,
            activeIndicatorColor: _diamondsPrice,
            heroAssetPath: 'assets/images/profile_wallet_diamond_hero.png',
            balanceLabel: 'رصيد الالماس الخاص بك :',
            packages: _diamondPackages,
            showAgentOffersBanner: true,
          )
        : const _WalletViewConfig(
            headerColor: _coinsHeader,
            packageColor: _coinsPackage,
            footerColor: _coinsPrice,
            activeSegmentColor: _diamondsTab,
            activeIndicatorColor: Color(0xFFFDD835),
            heroAssetPath: 'assets/images/profile_wallet_coins_hero.png',
            balanceLabel: 'رصيد الكوينز الخاص بك :',
            packages: _coinPackages,
            showAgentOffersBanner: false,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: config.headerColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(25),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 60, 18, 20),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              label: 'profile-wallet-back',
                              button: true,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                borderRadius: BorderRadius.circular(19),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: config.activeIndicatorColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'محفظتي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  label: 'profile-wallet-records',
                                  button: true,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.profileWalletRecords,
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        'تسجيل',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Semantics(
                                  label: 'profile-wallet-history',
                                  button: true,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.profileIncomeHistory,
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        'المحفوظات',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _WalletTabSwitcher(
                        selectedTab: _selectedTab,
                        activeColor: config.activeSegmentColor,
                        onChanged: (tab) {
                          setState(() {
                            _selectedTab = tab;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Image.asset(
                            config.heroAssetPath,
                            width: 100,
                            height: 100,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  config.balanceLabel,
                                  style: const TextStyle(
                                    color: _primaryBlue,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '5',
                                  style: TextStyle(
                                    color: _primaryBlue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      if (config.showAgentOffersBanner) ...[
                        const SizedBox(height: 14),
                        _WalletOfferBanner(
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.bootstrap);
                          },
                        ),
                        const SizedBox(height: 24),
                      ] else
                        const SizedBox(height: 25),
                      Wrap(
                        spacing: 15,
                        runSpacing: 20,
                        children: config.packages
                            .map(
                              (item) => _WalletPackageCard(
                                data: item,
                                packageColor: config.packageColor,
                                footerColor: config.footerColor,
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.bootstrap);
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: 285,
                        height: 46,
                        child: ElevatedButton(
                          key: const ValueKey('profile-wallet-contact'),
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.profileShippingAgency);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: config.footerColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'تواصل معنا الان',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _WalletTabSwitcher extends StatelessWidget {
  const _WalletTabSwitcher({
    required this.selectedTab,
    required this.activeColor,
    required this.onChanged,
  });

  final _WalletTab selectedTab;
  final Color activeColor;
  final ValueChanged<_WalletTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCoins = selectedTab == _WalletTab.coins;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 170,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: const ValueKey('profile-wallet-tab-coins'),
                onTap: () => onChanged(_WalletTab.coins),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCoins ? activeColor : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'كوينز',
                    style: TextStyle(
                      color: isCoins
                          ? Colors.white
                          : _ProfileWalletScreenState._inactiveTabText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              color: _ProfileWalletScreenState._inactiveTabText,
            ),
            Expanded(
              child: InkWell(
                key: const ValueKey('profile-wallet-tab-diamonds'),
                onTap: () => onChanged(_WalletTab.diamonds),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCoins ? Colors.transparent : activeColor,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'الماس',
                    style: TextStyle(
                      color: isCoins
                          ? _ProfileWalletScreenState._inactiveTabText
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletOfferBanner extends StatelessWidget {
  const _WalletOfferBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-wallet-agent-offers',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 343,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 35,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _ProfileWalletScreenState._primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  alignment: Alignment.centerRight,
                  child: const Text(
                    'اضغط هنا لعروض وكلاء الشحن الان !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Color(0x40000000),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 23,
                child: Transform.rotate(
                  angle: -0.22,
                  child: Image.asset(
                    'assets/images/profile_wallet_gift_banner.png',
                    width: 80,
                    height: 80,
                    filterQuality: FilterQuality.high,
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

class _WalletPackageCard extends StatelessWidget {
  const _WalletPackageCard({
    required this.data,
    required this.packageColor,
    required this.footerColor,
    required this.onTap,
  });

  final _WalletPackageData data;
  final Color packageColor;
  final Color footerColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 103,
          child: Column(
            children: [
              Container(
                height: 103,
                decoration: BoxDecoration(
                  color: packageColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Stack(
                  children: [
                    if (data.bonus != null)
                      Positioned(
                        top: 10,
                        left: 11,
                        child: Text(
                          data.bonus!,
                          style: const TextStyle(
                            color: _ProfileWalletScreenState._accentRed,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data.amount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Image.asset(
                            data.largeIconAssetPath,
                            width: 40,
                            height: 40,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: footerColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.footerLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (data.footerIconAssetPath != null) ...[
                          const SizedBox(width: 5),
                          Image.asset(
                            data.footerIconAssetPath!,
                            width: 14,
                            height: 14,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ],
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

class _WalletViewConfig {
  const _WalletViewConfig({
    required this.headerColor,
    required this.packageColor,
    required this.footerColor,
    required this.activeSegmentColor,
    required this.activeIndicatorColor,
    required this.heroAssetPath,
    required this.balanceLabel,
    required this.packages,
    required this.showAgentOffersBanner,
  });

  final Color headerColor;
  final Color packageColor;
  final Color footerColor;
  final Color activeSegmentColor;
  final Color activeIndicatorColor;
  final String heroAssetPath;
  final String balanceLabel;
  final List<_WalletPackageData> packages;
  final bool showAgentOffersBanner;
}

class _WalletPackageData {
  const _WalletPackageData({
    required this.amount,
    required this.footerLabel,
    required this.largeIconAssetPath,
    this.footerIconAssetPath,
    this.bonus,
  });

  final String amount;
  final String footerLabel;
  final String largeIconAssetPath;
  final String? footerIconAssetPath;
  final String? bonus;
}
