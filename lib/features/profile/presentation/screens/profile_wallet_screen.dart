import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/layout/responsive.dart';
import '../../data/profile_economy_repository.dart';

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
      packageId: 1,
      amount: '30990',
      footerLabel: '2,894,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
    ),
    _WalletPackageData(
      packageId: 2,
      amount: '6090',
      footerLabel: '578,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
    ),
    _WalletPackageData(
      packageId: 3,
      amount: '600',
      footerLabel: '57,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
      bonus: '+300',
    ),
    _WalletPackageData(
      packageId: 4,
      amount: '122990',
      footerLabel: '11,536,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
      bonus: '+1000',
    ),
    _WalletPackageData(
      packageId: 5,
      amount: '61990',
      footerLabel: '5,736,99 ج.م',
      largeIconAssetPath: 'assets/images/profile_wallet_diamond_small.png',
    ),
  ];

  static const List<_WalletPackageData> _coinPackages = [
    _WalletPackageData(
      packageId: 6,
      amount: '5000',
      footerLabel: '500',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      packageId: 7,
      amount: '1000',
      footerLabel: '100',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      packageId: 8,
      amount: '100',
      footerLabel: '10',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      packageId: 9,
      amount: '5000000',
      footerLabel: '500000',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      packageId: 10,
      amount: '100000',
      footerLabel: '10000',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
    _WalletPackageData(
      packageId: 11,
      amount: '10000',
      footerLabel: '1000',
      largeIconAssetPath: 'assets/images/profile_wallet_coin_large.png',
      footerIconAssetPath: 'assets/images/profile_wallet_coin_small_inline.png',
    ),
  ];

  _WalletTab _selectedTab = _WalletTab.diamonds;
  final ProfileEconomyRepository _economyRepository =
      ProfileEconomyRepository.instance;

  late WalletDashboardData _dashboard = WalletDashboardData(
    wallet: const EconomyWalletData(coinsBalance: 1235, diamondsBalance: 5),
    diamondPackages: _diamondPackages
        .map((item) => item.toPackageData('diamonds'))
        .toList(),
    coinPackages: _coinPackages
        .map((item) => item.toPackageData('coins'))
        .toList(),
  );
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final dashboard = await _economyRepository.loadWalletDashboard();
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
      });
    } catch (_) {}
  }

  Future<void> _applyPackage(int packageId) async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      final dashboard = await _economyRepository.topUpWallet(
        packageId: packageId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم شحن الرصيد بنجاح')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final isDiamonds = _selectedTab == _WalletTab.diamonds;
    final packages = isDiamonds
        ? _dashboard.diamondPackages
        : _dashboard.coinPackages;
    final config = isDiamonds
        ? _WalletViewConfig(
            headerColor: _diamondsHeader,
            packageColor: _diamondsPackage,
            footerColor: _diamondsPrice,
            activeSegmentColor: _diamondsTab,
            activeIndicatorColor: _diamondsPrice,
            heroAssetPath: 'assets/images/profile_wallet_diamond_hero.png',
            balanceLabel: 'رصيد الالماس الخاص بك :',
            packages: packages
                .map((item) => _WalletPackageData.fromPackage(item))
                .toList(),
            showAgentOffersBanner: true,
          )
        : _WalletViewConfig(
            headerColor: _coinsHeader,
            packageColor: _coinsPackage,
            footerColor: _coinsPrice,
            activeSegmentColor: _diamondsTab,
            activeIndicatorColor: Color(0xFFFDD835),
            heroAssetPath: 'assets/images/profile_wallet_coins_hero.png',
            balanceLabel: 'رصيد الكوينز الخاص بك :',
            packages: packages
                .map((item) => _WalletPackageData.fromPackage(item))
                .toList(),
            showAgentOffersBanner: false,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            color: _primaryBlue,
            onRefresh: _loadWallet,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveContent(
                maxWidth: 500,
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
                      padding: EdgeInsets.fromLTRB(
                        metrics.pageHorizontalPadding(),
                        metrics.spacing(60, min: 42, max: 64),
                        metrics.pageHorizontalPadding(),
                        metrics.spacing(20, min: 16, max: 24),
                      ),
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
                                      width: metrics.spacing(
                                        38,
                                        min: 34,
                                        max: 42,
                                      ),
                                      height: metrics.spacing(
                                        38,
                                        min: 34,
                                        max: 42,
                                      ),
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
                                    SizedBox(
                                      width: metrics.spacing(
                                        10,
                                        min: 6,
                                        max: 10,
                                      ),
                                    ),
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
                          SizedBox(
                            height: metrics.spacing(10, min: 8, max: 12),
                          ),
                          _WalletTabSwitcher(
                            selectedTab: _selectedTab,
                            activeColor: config.activeSegmentColor,
                            onChanged: (tab) {
                              setState(() {
                                _selectedTab = tab;
                              });
                            },
                          ),
                          SizedBox(height: metrics.spacing(8, min: 6, max: 10)),
                          Row(
                            children: [
                              Image.asset(
                                config.heroAssetPath,
                                width: metrics.spacing(100, min: 82, max: 110),
                                height: metrics.spacing(100, min: 82, max: 110),
                                filterQuality: FilterQuality.high,
                              ),
                              SizedBox(
                                width: metrics.spacing(20, min: 12, max: 20),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      config.balanceLabel,
                                      style: TextStyle(
                                        color: _primaryBlue,
                                        fontSize: metrics.font(
                                          15,
                                          min: 13,
                                          max: 16,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                      height: metrics.spacing(
                                        6,
                                        min: 4,
                                        max: 8,
                                      ),
                                    ),
                                    Text(
                                      isDiamonds
                                          ? _dashboard.wallet.diamondsBalance
                                                .toString()
                                          : _dashboard.wallet.coinsBalance
                                                .toString(),
                                      style: TextStyle(
                                        color: _primaryBlue,
                                        fontSize: metrics.font(
                                          20,
                                          min: 18,
                                          max: 22,
                                        ),
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
                      padding: EdgeInsets.fromLTRB(
                        metrics.pageHorizontalPadding(compact: 12, regular: 16),
                        0,
                        metrics.pageHorizontalPadding(compact: 12, regular: 16),
                        24,
                      ),
                      child: Column(
                        children: [
                          if (config.showAgentOffersBanner) ...[
                            SizedBox(
                              height: metrics.spacing(14, min: 12, max: 16),
                            ),
                            _WalletOfferBanner(
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.profileShippingAgency);
                              },
                            ),
                            SizedBox(
                              height: metrics.spacing(24, min: 18, max: 24),
                            ),
                          ] else
                            SizedBox(
                              height: metrics.spacing(25, min: 18, max: 25),
                            ),
                          Wrap(
                            spacing: metrics.spacing(15, min: 10, max: 15),
                            runSpacing: metrics.spacing(20, min: 12, max: 20),
                            children: config.packages
                                .map(
                                  (item) => _WalletPackageCard(
                                    data: item,
                                    packageColor: config.packageColor,
                                    footerColor: config.footerColor,
                                    onTap: () {
                                      _applyPackage(item.packageId);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          SizedBox(
                            height: metrics.spacing(25, min: 18, max: 25),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: metrics.spacing(46, min: 42, max: 48),
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
                              child: Text(
                                'تواصل معنا الان',
                                style: TextStyle(
                                  fontSize: metrics.font(15, min: 13, max: 16),
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
    final metrics = ResponsiveMetrics.of(context);
    final isCoins = selectedTab == _WalletTab.coins;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: metrics.spacing(170, min: 150, max: 180),
        height: metrics.spacing(34, min: 32, max: 38),
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
                      fontSize: metrics.font(15, min: 13, max: 16),
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
                      fontSize: metrics.font(15, min: 13, max: 16),
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
    final metrics = ResponsiveMetrics.of(context);

    return Semantics(
      label: 'profile-wallet-agent-offers',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: double.infinity,
          height: metrics.spacing(96, min: 90, max: 108),
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
                right: metrics.spacing(23, min: 14, max: 23),
                child: Transform.rotate(
                  angle: -0.22,
                  child: Image.asset(
                    'assets/images/profile_wallet_gift_banner.png',
                    width: metrics.spacing(80, min: 62, max: 80),
                    height: metrics.spacing(80, min: 62, max: 80),
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
    final metrics = ResponsiveMetrics.of(context);
    final availableWidth =
        (metrics.maxContentWidth == double.infinity
            ? metrics.screenWidth
            : metrics.maxContentWidth) -
        (metrics.pageHorizontalPadding(compact: 12, regular: 16) * 2) -
        metrics.spacing(15, min: 10, max: 15);
    final cardWidth = (availableWidth / 2).clamp(138.0, 170.0).toDouble();

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: cardWidth,
          child: Column(
            children: [
              Container(
                height: cardWidth,
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
                          style: TextStyle(
                            color: _ProfileWalletScreenState._accentRed,
                            fontSize: metrics.font(8, min: 8, max: 9),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: metrics.font(20, min: 18, max: 22),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: metrics.spacing(2, min: 2, max: 4)),
                          Image.asset(
                            data.largeIconAssetPath,
                            width: metrics.spacing(40, min: 34, max: 44),
                            height: metrics.spacing(40, min: 34, max: 44),
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: metrics.spacing(30, min: 28, max: 34),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: metrics.font(12, min: 11, max: 13),
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
    required this.packageId,
    required this.amount,
    required this.footerLabel,
    required this.largeIconAssetPath,
    this.footerIconAssetPath,
    this.bonus,
  });

  final int packageId;
  final String amount;
  final String footerLabel;
  final String largeIconAssetPath;
  final String? footerIconAssetPath;
  final String? bonus;

  factory _WalletPackageData.fromPackage(WalletPackageData package) {
    final isCoins = package.walletType == 'coins';
    return _WalletPackageData(
      packageId: package.id,
      amount: package.amount.toString(),
      footerLabel: package.priceLabel,
      largeIconAssetPath: isCoins
          ? 'assets/images/profile_wallet_coin_large.png'
          : 'assets/images/profile_wallet_diamond_small.png',
      footerIconAssetPath: isCoins
          ? 'assets/images/profile_wallet_coin_small_inline.png'
          : null,
      bonus: package.bonusAmount > 0 ? '+${package.bonusAmount}' : null,
    );
  }

  WalletPackageData toPackageData(String walletType) {
    return WalletPackageData(
      id: packageId,
      walletType: walletType,
      amount: int.tryParse(amount) ?? 0,
      bonusAmount: int.tryParse((bonus ?? '').replaceAll('+', '')) ?? 0,
      priceLabel: footerLabel,
    );
  }
}
