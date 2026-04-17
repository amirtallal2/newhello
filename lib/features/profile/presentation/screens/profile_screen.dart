import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';
import 'profile_connections_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFEDEDED);
  static const Color _cardShadow = Color(0x40000000);

  static Future<void> showLogoutConfirmationDialog(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'profile-logout-dialog',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: Container(color: const Color(0x4DB3A1A1)),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  key: const ValueKey('profile-logout-dialog'),
                  width: 306,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'هل انت متاكد انك تريد تسجيل الخروج',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 20 / 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              key: const ValueKey('profile-logout-confirm'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.authEntry,
                                  (route) => false,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                                minimumSize: const Size(72, 28),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  height: 20 / 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 28),
                            TextButton(
                              key: const ValueKey('profile-logout-cancel'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                                minimumSize: const Size(48, 28),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'الغاء',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  height: 20 / 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static const List<_ProfileStatData> _stats = [
    _ProfileStatData(
      label: 'اتابع',
      value: '50',
      tab: ProfileConnectionsTab.following,
    ),
    _ProfileStatData(
      label: 'المتابعون',
      value: '100',
      tab: ProfileConnectionsTab.followers,
    ),
    _ProfileStatData(
      label: 'الأصدقاء',
      value: '123',
      tab: ProfileConnectionsTab.friends,
    ),
  ];

  static const List<_ProfileActionItemData> _walletItems = [
    _ProfileActionItemData(
      label: 'الحقيبة',
      assetPath: 'assets/images/profile_bag_icon.png',
      backgroundColor: Color(0xFF96CAB2),
    ),
    _ProfileActionItemData(
      label: 'المتجر',
      assetPath: 'assets/images/profile_store_icon.png',
      backgroundColor: Color(0xFF96DFD8),
    ),
    _ProfileActionItemData(
      label: 'الشحن',
      assetPath: 'assets/images/profile_charge_icon.png',
      backgroundColor: Color(0xFFE6C1B3),
    ),
    _ProfileActionItemData(
      label: 'الدخل',
      assetPath: 'assets/images/profile_income_icon.png',
      backgroundColor: Color(0xFFE6D3B1),
    ),
  ];

  static const List<_ProfileActionItemData> _statusItems = [
    _ProfileActionItemData(
      label: 'المستوى',
      assetPath: 'assets/images/profile_level_icon.png',
      backgroundColor: Color(0xFFCCFAC0),
    ),
    _ProfileActionItemData(
      label: 'SVIP',
      assetPath: 'assets/images/profile_svip_icon.png',
      backgroundColor: Color(0xFFCBF5F9),
    ),
    _ProfileActionItemData(
      label: 'VIP',
      assetPath: 'assets/images/profile_vip_icon.png',
      backgroundColor: Color(0xFFEECBB7),
    ),
    _ProfileActionItemData(
      label: 'المهام',
      assetPath: 'assets/images/profile_tasks_icon.png',
      backgroundColor: Color(0xFF98D0FA),
    ),
  ];

  static const List<_ProfileActionItemData> _agencyItems = [
    _ProfileActionItemData(
      label: 'كود الدعوة',
      assetPath: 'assets/images/profile_invitation_icon.png',
      backgroundColor: Color(0xFFE8C6AE),
    ),
    _ProfileActionItemData(
      label: 'انضم إلى وكالة',
      assetPath: 'assets/images/profile_join_agency_icon.png',
      backgroundColor: Color(0xFFB5EAFB),
    ),
    _ProfileActionItemData(
      label: 'فتح وكالة',
      assetPath: 'assets/images/profile_open_agency_icon.png',
      backgroundColor: Color(0xFFEDCDCA),
    ),
  ];

  static const List<_ProfileMenuActionData> _menuItems = [
    _ProfileMenuActionData(
      label: 'مركز الدعم',
      assetPath: 'assets/images/profile_support_icon.png',
    ),
    _ProfileMenuActionData(
      label: 'الشارات',
      assetPath: 'assets/images/profile_badges_icon.png',
    ),
    _ProfileMenuActionData(
      label: 'كيفية استخدام التطبيق',
      assetPath: 'assets/images/profile_app_usage_icon.png',
    ),
    _ProfileMenuActionData(
      label: 'الإعدادات',
      assetPath: 'assets/images/profile_settings_icon.png',
    ),
    _ProfileMenuActionData(
      label: 'تسجيل الخروج',
      assetPath: 'assets/images/profile_logout_icon.png',
      isLogout: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: _surfaceGrey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ProfileHeader(
                        onTopActionTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                        },
                        onProfileTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.profileEdit);
                        },
                        onStatTap: (tab) {
                          Navigator.of(context).pushNamed(
                            AppRoutes.profileConnections,
                            arguments: ProfileConnectionsScreenArgs(
                              initialTab: tab,
                              isCurrentUser: true,
                            ),
                          );
                        },
                      ),
                      Transform.translate(
                        offset: const Offset(0, -58),
                        child: Column(
                          children: [
                            _ProfileActionCard(
                              items: _walletItems,
                              onItemTap: (item) {
                                if (item.label == 'الحقيبة') {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileBag);
                                  return;
                                }

                                if (item.label == 'المتجر') {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileStore);
                                  return;
                                }

                                if (item.label == 'الدخل') {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileIncome);
                                  return;
                                }

                                if (item.label == 'الشحن') {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileWallet);
                                  return;
                                }

                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.bootstrap);
                              },
                            ),
                            const SizedBox(height: 10),
                            _ProfileActionCard(
                              items: _statusItems,
                              onItemTap: (item) {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.bootstrap);
                              },
                            ),
                            const SizedBox(height: 10),
                            _ProfileActionCard(
                              items: _agencyItems,
                              onItemTap: (item) {
                                if (item.label == 'انضم إلى وكالة') {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileJoinAgency);
                                  return;
                                }

                                if (item.label == 'فتح وكالة') {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileOpenAgency);
                                  return;
                                }

                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.bootstrap);
                              },
                            ),
                            const SizedBox(height: 20),
                            _ProfileMenuSection(
                              items: _menuItems,
                              onTap: (item) {
                                if (item.isLogout) {
                                  showLogoutConfirmationDialog(context);
                                  return;
                                }

                                if (item.label == 'الإعدادات') {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileEdit);
                                  return;
                                }

                                if (item.label == 'مركز الدعم') {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.profileSupportCenter);
                                  return;
                                }

                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.bootstrap);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
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
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.onTopActionTap,
    required this.onProfileTap,
    required this.onStatTap,
  });

  final VoidCallback onTopActionTap;
  final VoidCallback onProfileTap;
  final ValueChanged<ProfileConnectionsTab> onStatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ProfileScreen._primaryBlue,
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 82),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onTopActionTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF9DB2CE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/profile_top_icon.png',
                  width: 24,
                  height: 24,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'profile-edit-entry',
            button: true,
            child: InkWell(
              key: const ValueKey('profile-edit-entry'),
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    const _ProfileAvatar(),
                    const SizedBox(height: 10),
                    const Text(
                      'بسمة أحمد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 20 / 15,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Color(0x40000000),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Shark.island',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 20 / 10,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Color(0x40000000),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/profile_country_flag.png',
                          width: 15,
                          height: 15,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ID:516451',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Color(0x40000000),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset(
                          'assets/images/profile_agency_flag.png',
                          width: 20,
                          height: 20,
                          filterQuality: FilterQuality.high,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: ProfileScreen._stats
                  .map(
                    (item) => Expanded(
                      child: _ProfileStat(
                        label: item.label,
                        value: item.value,
                        onTap: () => onStatTap(item.tab),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 11),
          const _ProfileLevelBar(),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 4),
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/profile_avatar.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFF34A853),
                shape: BoxShape.circle,
                border: Border.all(color: ProfileScreen._primaryBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-stat-$label',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 20 / 15,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Color(0x40000000),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 20 / 12,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Color(0x40000000),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLevelBar extends StatelessWidget {
  const _ProfileLevelBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 303,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          Positioned(
            right: 100,
            left: 0,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF5590CD),
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 0,
            bottom: -11,
            child: _LevelChip(label: 'Lv.0'),
          ),
          const Positioned(
            right: 0,
            bottom: -11,
            child: _LevelChip(label: 'Lv.1'),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 15,
      decoration: BoxDecoration(
        color: const Color(0xFF9DB2CE),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w500,
          height: 20 / 7,
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({required this.items, required this.onItemTap});

  final List<_ProfileActionItemData> items;
  final ValueChanged<_ProfileActionItemData> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: ProfileScreen._cardShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: items
              .map(
                (item) => Expanded(
                  child: _ProfileActionItem(
                    data: item,
                    onTap: () => onItemTap(item),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ProfileActionItem extends StatelessWidget {
  const _ProfileActionItem({required this.data, required this.onTap});

  final _ProfileActionItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-action-${data.label}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: data.backgroundColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  data.assetPath,
                  width: 30,
                  height: 30,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ProfileScreen._primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 20 / 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuSection extends StatelessWidget {
  const _ProfileMenuSection({required this.items, required this.onTap});

  final List<_ProfileMenuActionData> items;
  final ValueChanged<_ProfileMenuActionData> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => onTap(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: ProfileScreen._primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              height: 20 / 10,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Image.asset(
                            item.assetPath,
                            width: 30,
                            height: 30,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileStatData {
  const _ProfileStatData({
    required this.label,
    required this.value,
    required this.tab,
  });

  final String label;
  final String value;
  final ProfileConnectionsTab tab;
}

class _ProfileActionItemData {
  const _ProfileActionItemData({
    required this.label,
    required this.assetPath,
    required this.backgroundColor,
  });

  final String label;
  final String assetPath;
  final Color backgroundColor;
}

class _ProfileMenuActionData {
  const _ProfileMenuActionData({
    required this.label,
    required this.assetPath,
    this.isLogout = false,
  });

  final String label;
  final String assetPath;
  final bool isLogout;
}
