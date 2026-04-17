import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../home/presentation/widgets/main_bottom_navigation.dart';

class ProfileStoreScreen extends StatelessWidget {
  const ProfileStoreScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _surfaceGrey = Color(0xFFF4F4F4);

  static const List<_StoreCategoryData> _categories = [
    _StoreCategoryData(
      label: 'الاطارات',
      cardAssetPath: 'assets/images/profile_store_frames_card.png',
      iconAssetPath: 'assets/images/profile_store_frames_icon.png',
      labelAlignment: Alignment.topRight,
      labelPadding: EdgeInsets.only(top: 14, right: 15),
      iconOffset: Offset(20, 8),
      routeName: AppRoutes.profileStoreFrames,
    ),
    _StoreCategoryData(
      label: 'الاطارات المتحركة',
      cardAssetPath: 'assets/images/profile_store_animated_frames_card.png',
      iconAssetPath: 'assets/images/profile_store_animated_frames_icon.png',
      labelAlignment: Alignment.topLeft,
      labelPadding: EdgeInsets.only(top: 14, left: 14),
      iconOffset: Offset(-20, 8),
      routeName: AppRoutes.profileStoreAnimatedFrames,
    ),
    _StoreCategoryData(
      label: 'الخلفيات',
      cardAssetPath: 'assets/images/profile_store_backgrounds_card.png',
      iconAssetPath: 'assets/images/profile_store_backgrounds_icon.png',
      labelAlignment: Alignment.topRight,
      labelPadding: EdgeInsets.only(top: 14, right: 15),
      iconOffset: Offset(17, 8),
      routeName: AppRoutes.profileStoreBackgrounds,
    ),
    _StoreCategoryData(
      label: 'الدخلات',
      cardAssetPath: 'assets/images/profile_store_entry_effects_card.png',
      iconAssetPath: 'assets/images/profile_store_entry_effects_icon.png',
      labelAlignment: Alignment.topLeft,
      labelPadding: EdgeInsets.only(top: 14, left: 15),
      iconOffset: Offset(-20, 8),
      routeName: AppRoutes.profileStoreEntryEffects,
    ),
    _StoreCategoryData(
      label: 'قبعات الدردشة',
      cardAssetPath: 'assets/images/profile_store_chat_hats_card.png',
      iconAssetPath: 'assets/images/profile_store_chat_hats_icon.png',
      labelAlignment: Alignment.topRight,
      labelPadding: EdgeInsets.only(top: 14, right: 15),
      iconOffset: Offset(20, 8),
      routeName: AppRoutes.profileStoreChatFrames,
    ),
    _StoreCategoryData(
      label: 'استقراطيه',
      cardAssetPath: 'assets/images/profile_store_aristocracy_card.png',
      iconAssetPath: 'assets/images/profile_store_aristocracy_icon.png',
      labelAlignment: Alignment.topLeft,
      labelPadding: EdgeInsets.only(top: 14, left: 15),
      iconOffset: Offset(-20, 8),
    ),
  ];

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
                      label: 'profile-store-back',
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
                    'المتجر',
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
                padding: const EdgeInsets.fromLTRB(17, 39, 17, 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 20.0;
                    final cardWidth = (constraints.maxWidth - spacing) / 2;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 20,
                      children: _categories
                          .map(
                            (category) => SizedBox(
                              width: cardWidth,
                              child: _StoreCategoryCard(category: category),
                            ),
                          )
                          .toList(),
                    );
                  },
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

class _StoreCategoryCard extends StatelessWidget {
  const _StoreCategoryCard({required this.category});

  final _StoreCategoryData category;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 161 / 159,
      child: Semantics(
        label: 'profile-store-category-${category.label}',
        button: true,
        child: InkWell(
          key: ValueKey('profile-store-category-${category.label}'),
          onTap: () {
            final routeName = category.routeName ?? AppRoutes.bootstrap;
            Navigator.of(context).pushNamed(routeName);
          },
          borderRadius: BorderRadius.circular(15),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(category.cardAssetPath),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: category.labelAlignment,
                  child: Padding(
                    padding: category.labelPadding,
                    child: Text(
                      category.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
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
                Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: category.iconOffset,
                    child: Image.asset(
                      category.iconAssetPath,
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
      ),
    );
  }
}

class _StoreCategoryData {
  const _StoreCategoryData({
    required this.label,
    required this.cardAssetPath,
    required this.iconAssetPath,
    required this.labelAlignment,
    required this.labelPadding,
    required this.iconOffset,
    this.routeName,
  });

  final String label;
  final String cardAssetPath;
  final String iconAssetPath;
  final Alignment labelAlignment;
  final EdgeInsets labelPadding;
  final Offset iconOffset;
  final String? routeName;
}
