import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileStoreBackgroundsScreen extends StatelessWidget {
  const ProfileStoreBackgroundsScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);
  static const Color _secondaryBlue = Color(0xFF9DB2CE);

  static const int _itemCount = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceGrey,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 40),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: 'profile-store-backgrounds-back',
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
                    'الخلفيات',
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
                padding: const EdgeInsets.fromLTRB(17, 10, 17, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 1, bottom: 11),
                        child: Text(
                          'جديد',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 20.0;
                        final cardWidth = (constraints.maxWidth - spacing) / 2;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: 20,
                          children: List.generate(_itemCount, (index) {
                            return SizedBox(
                              width: cardWidth,
                              child: _BackgroundStoreItemCard(index: index),
                            );
                          }),
                        );
                      },
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

class _BackgroundStoreItemCard extends StatelessWidget {
  const _BackgroundStoreItemCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'معاينة',
                style: TextStyle(
                  color: ProfileStoreBackgroundsScreen._primaryBlue,
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
                  color: ProfileStoreBackgroundsScreen._primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const _BackgroundPreviewBox(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BackgroundStoreActionButton(
                  label: 'ارسال',
                  backgroundColor: ProfileStoreBackgroundsScreen._secondaryBlue,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.profileStoreSendFrame);
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _BackgroundStoreActionButton(
                  buttonKey: ValueKey(
                    'profile-store-backgrounds-item-buy-$index',
                  ),
                  label: 'شراء',
                  backgroundColor: ProfileStoreBackgroundsScreen._primaryBlue,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundPreviewBox extends StatelessWidget {
  const _BackgroundPreviewBox();

  static const List<Offset> _seatOffsets = [
    Offset(1, 11),
    Offset(10, 11),
    Offset(20, 11),
    Offset(29, 11),
    Offset(1, 20),
    Offset(10, 20),
    Offset(20, 20),
    Offset(29, 20),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 95,
      child: Center(
        child: SizedBox(
          width: 41,
          height: 87,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/profile_store_background_preview.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              Positioned(
                left: 2,
                top: 8,
                child: SizedBox(
                  width: 37,
                  height: 43,
                  child: Stack(
                    children: [
                      ..._seatOffsets.map(
                        (offset) => Positioned(
                          left: offset.dx,
                          top: offset.dy,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: const Color(0x809DB2CE),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 15,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0x669DB2CE),
                              width: 0.6,
                            ),
                          ),
                        ),
                      ),
                      ..._seatOffsets.map(
                        (offset) => Positioned(
                          left: offset.dx + 1,
                          top: offset.dy + 2,
                          child: Image.asset(
                            'assets/images/profile_store_background_mic_icon.png',
                            width: 3,
                            height: 3,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 31,
                        child: Container(
                          width: 36,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0x80232222),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      const Positioned(left: 0, top: 1, child: _BlueDot()),
                      const Positioned(left: 5, top: 1, child: _BlueDot()),
                      Positioned(
                        left: 6,
                        top: 2,
                        child: Image.asset(
                          'assets/images/profile_store_background_settings_icon.png',
                          width: 3,
                          height: 3,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      Positioned(
                        left: 33,
                        top: 1,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0x669DB2CE),
                              width: 0.4,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 1,
                        top: 2,
                        child: Image.asset(
                          'assets/images/profile_store_background_power_icon.png',
                          width: 3,
                          height: 3,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
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

class _BlueDot extends StatelessWidget {
  const _BlueDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: ProfileStoreBackgroundsScreen._primaryBlue,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BackgroundStoreActionButton extends StatelessWidget {
  const _BackgroundStoreActionButton({
    this.buttonKey,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final Key? buttonKey;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: ElevatedButton(
        key: buttonKey,
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
