import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../controllers/room_background_controller.dart';
import '../widgets/room_background_view.dart';
import 'room_general_settings_screen.dart';
import 'room_settings_screen.dart';

class RoomBackgroundSelectionScreen extends StatefulWidget {
  const RoomBackgroundSelectionScreen({super.key});

  static const Color _modalTop = Color(0xFF7FBAF8);
  static const Color _modalBottom = Color(0xFF285F98);
  static const Color _saveGreen = Color(0xFF1F9254);

  @override
  State<RoomBackgroundSelectionScreen> createState() =>
      _RoomBackgroundSelectionScreenState();
}

class _RoomBackgroundSelectionScreenState
    extends State<RoomBackgroundSelectionScreen> {
  static const List<String> _previewAssets = [
    'assets/images/room_background_option_1.jpg',
    'assets/images/room_background_option_1.jpg',
    'assets/images/room_background_option_1.jpg',
    'assets/images/room_background_option_2.jpg',
    'assets/images/room_background_option_2.jpg',
    'assets/images/room_background_option_2.jpg',
    'assets/images/room_background_option_3.jpg',
    'assets/images/room_background_option_3.jpg',
    'assets/images/room_background_option_3.jpg',
  ];
  static const List<String> _purchasedPreviewAssets = _previewAssets;

  late String _selectedBackgroundAsset;
  _RoomBackgroundTab _activeTab = _RoomBackgroundTab.background;

  @override
  void initState() {
    super.initState();
    final currentAsset =
        RoomBackgroundController.instance.selectedBackgroundAsset.value;
    _selectedBackgroundAsset =
        RoomBackgroundController.availableBackgroundAssets.contains(
          currentAsset,
        )
        ? currentAsset
        : RoomBackgroundController.availableBackgroundAssets.first;
  }

  void _handleBackdropActionTap(String label) {
    if (label == 'صورة الخلفية') {
      return;
    }

    if (label == 'اعدادات الغرفة') {
      Navigator.of(context).pushReplacementNamed(AppRoutes.roomGeneralSettings);
      return;
    }

    if (label == 'كمية الميكروفون') {
      Navigator.of(context).pushReplacementNamed(AppRoutes.roomMicQuantity);
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.bootstrap);
  }

  void _saveBackgroundSelection() {
    RoomBackgroundController.instance.updateBackground(
      _selectedBackgroundAsset,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RoomBackgroundView(),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: const Color(0x05FFFFFF)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: RoomGeneralSettingsBackdropPanel(
              onActionTap: _handleBackdropActionTap,
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 173,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 332),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: _RoomBackgroundSelectionModal(
                          activeTab: _activeTab,
                          selectedAsset: _selectedBackgroundAsset,
                          previewAssets:
                              _activeTab == _RoomBackgroundTab.background
                              ? _previewAssets
                              : _purchasedPreviewAssets,
                          onTabChanged: (tab) {
                            setState(() {
                              _activeTab = tab;
                            });
                          },
                          onBackgroundSelected: (assetPath) {
                            setState(() {
                              _selectedBackgroundAsset = assetPath;
                            });
                          },
                          onSaveTap: _saveBackgroundSelection,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 18,
                  bottom: 22,
                  child: RoomSettingsBottomComposer(
                    onControlTap: () {},
                    onMuteTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                    },
                    onChatTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                    },
                    onGiftTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                    },
                    onSendTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomBackgroundSelectionModal extends StatelessWidget {
  const _RoomBackgroundSelectionModal({
    required this.activeTab,
    required this.selectedAsset,
    required this.previewAssets,
    required this.onTabChanged,
    required this.onBackgroundSelected,
    required this.onSaveTap,
  });

  final _RoomBackgroundTab activeTab;
  final String selectedAsset;
  final List<String> previewAssets;
  final ValueChanged<_RoomBackgroundTab> onTabChanged;
  final ValueChanged<String> onBackgroundSelected;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RoomBackgroundSelectionScreen._modalTop,
            RoomBackgroundSelectionScreen._modalBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackgroundSelectionTabs(
            activeTab: activeTab,
            onTabChanged: onTabChanged,
          ),
          const SizedBox(height: 20),
          GridView.builder(
            itemCount: previewAssets.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 10,
              childAspectRatio: 0.864,
            ),
            itemBuilder: (context, index) {
              final assetPath = previewAssets[index];
              return _BackgroundOptionCard(
                assetPath: assetPath,
                isSelected: assetPath == selectedAsset,
                onTap: () => onBackgroundSelected(assetPath),
                cardKey: ValueKey('room-background-option-$index'),
              );
            },
          ),
          const SizedBox(height: 24),
          InkWell(
            key: const ValueKey('room-background-save'),
            onTap: onSaveTap,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 33,
              decoration: BoxDecoration(
                color: RoomBackgroundSelectionScreen._saveGreen,
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: const Text(
                'حفظ التغيرات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundSelectionTabs extends StatelessWidget {
  const _BackgroundSelectionTabs({
    required this.activeTab,
    required this.onTabChanged,
  });

  final _RoomBackgroundTab activeTab;
  final ValueChanged<_RoomBackgroundTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BackgroundTabButton(
          key: const ValueKey('room-background-tab-purchased'),
          label: 'تم الشراء',
          isActive: activeTab == _RoomBackgroundTab.purchased,
          onTap: () => onTabChanged(_RoomBackgroundTab.purchased),
        ),
        const SizedBox(width: 50),
        _BackgroundTabButton(
          key: const ValueKey('room-background-tab-background'),
          label: 'الخلفية',
          isActive: activeTab == _RoomBackgroundTab.background,
          onTap: () => onTabChanged(_RoomBackgroundTab.background),
        ),
      ],
    );
  }
}

class _BackgroundTabButton extends StatelessWidget {
  const _BackgroundTabButton({
    required super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF285F98) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: label == 'الخلفية' ? 31 : 39,
            height: 1,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF285F98) : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOptionCard extends StatelessWidget {
  const _BackgroundOptionCard({
    required this.assetPath,
    required this.isSelected,
    required this.onTap,
    required this.cardKey,
  });

  final String assetPath;
  final bool isSelected;
  final VoidCallback onTap;
  final Key cardKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: cardKey,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

enum _RoomBackgroundTab { background, purchased }
