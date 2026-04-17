import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileBagScreen extends StatefulWidget {
  const ProfileBagScreen({super.key});

  @override
  State<ProfileBagScreen> createState() => _ProfileBagScreenState();
}

class _ProfileBagScreenState extends State<ProfileBagScreen> {
  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _secondaryBlue = Color(0xFF9DB2CE);

  static const List<String> _tabs = ['الاطارات المتحركة', 'رسم', 'الدخلات'];

  final List<_BagItemData> _items = List<_BagItemData>.generate(
    4,
    (_) => const _BagItemData(),
  );

  String _activeTab = _tabs.first;
  int? _selectedItemIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 70, 18, 24),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              label: 'profile-bag-back',
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
                            'حقيبتي',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      Row(
                        children: _tabs
                            .map(
                              (tab) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7.5,
                                  ),
                                  child: _BagTabButton(
                                    label: tab,
                                    isActive: _activeTab == tab,
                                    onTap: () {
                                      setState(() {
                                        _activeTab = tab;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 20.0;
                          final cardWidth =
                              (constraints.maxWidth - spacing) / 2;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: 20,
                            children: List.generate(_items.length, (index) {
                              return SizedBox(
                                width: cardWidth,
                                child: _BagItemCard(
                                  index: index,
                                  isSelected: _selectedItemIndex == index,
                                  onTap: () {
                                    setState(() {
                                      _selectedItemIndex = index;
                                    });
                                  },
                                  onUseTap: () {
                                    setState(() {
                                      _selectedItemIndex = index;
                                    });
                                  },
                                  onCancelTap: () {
                                    setState(() {
                                      if (_selectedItemIndex == index) {
                                        _selectedItemIndex = null;
                                      }
                                    });
                                  },
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _BottomActionButton(
                              buttonKey: const ValueKey('profile-bag-wear'),
                              label: 'ارتداء',
                              backgroundColor: const Color(0xFF23D9BF),
                              onTap: () {
                                if (_selectedItemIndex == null) {
                                  return;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _BottomActionButton(
                              buttonKey: const ValueKey('profile-bag-finish'),
                              label: 'انهاء',
                              backgroundColor: const Color(0xFFE99F40),
                              onTap: () {
                                if (_selectedItemIndex == null) {
                                  return;
                                }
                                setState(() {
                                  _selectedItemIndex = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _BottomActionButton(
                              buttonKey: const ValueKey('profile-bag-remove'),
                              label: 'ازالة',
                              backgroundColor: const Color(0xFFE86043),
                              onTap: () {
                                if (_selectedItemIndex == null) {
                                  return;
                                }
                                setState(() {
                                  _items.removeAt(_selectedItemIndex!);
                                  _selectedItemIndex = null;
                                });
                              },
                            ),
                          ),
                        ],
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

class _BagTabButton extends StatelessWidget {
  const _BagTabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? _ProfileBagScreenState._primaryBlue
              : _ProfileBagScreenState._secondaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _BagItemCard extends StatelessWidget {
  const _BagItemCard({
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onUseTap,
    required this.onCancelTap,
  });

  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onUseTap;
  final VoidCallback onCancelTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'profile-bag-item-$index',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: isSelected
                ? Border.all(
                    color: _ProfileBagScreenState._primaryBlue,
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'معاينة',
                    style: TextStyle(
                      color: _ProfileBagScreenState._primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/images/profile_store_coin_icon.png',
                    width: 18,
                    height: 18,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    '7 أيام',
                    style: TextStyle(
                      color: _ProfileBagScreenState._primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const _BagItemPreview(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BagCardActionButton(
                      label: 'الغاء',
                      backgroundColor: _ProfileBagScreenState._secondaryBlue,
                      onTap: onCancelTap,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _BagCardActionButton(
                      label: 'استخدام',
                      backgroundColor: _ProfileBagScreenState._primaryBlue,
                      onTap: onUseTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BagItemPreview extends StatelessWidget {
  const _BagItemPreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 95,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 17,
            child: ClipOval(
              child: Image.asset(
                'assets/images/profile_store_frames_preview_avatar.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/images/profile_store_frames_preview_overlay.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

class _BagCardActionButton extends StatelessWidget {
  const _BagCardActionButton({
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.buttonKey,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _BagItemData {
  const _BagItemData();
}
