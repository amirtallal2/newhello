import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../widgets/room_background_view.dart';

class RoomSettingsScreen extends StatelessWidget {
  const RoomSettingsScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _panelTop = Color(0xFF7FBAF8);
  static const Color _panelBottom = Color(0xFF285F98);
  static const Color _seatFill = Color(0x809DB2CE);
  static const Color _composerFill = Color(0x80232222);

  static const List<_RoomSettingAction> _generalSettings = [
    _RoomSettingAction(
      label: 'اعدادات الغرفة',
      assetPath: 'assets/images/room_general_settings_icon.png',
    ),
    _RoomSettingAction(
      label: 'موسيقي',
      assetPath: 'assets/images/room_music_setting_icon.png',
    ),
    _RoomSettingAction(
      label: 'صورة الخلفية',
      assetPath: 'assets/images/room_background_setting_icon.png',
    ),
    _RoomSettingAction(
      label: 'قفل الغرفة',
      assetPath: 'assets/images/room_lock_setting_icon.png',
    ),
    _RoomSettingAction(
      label: 'مشاركة الغرفة',
      assetPath: 'assets/images/room_share_setting_icon.png',
    ),
    _RoomSettingAction(
      label: 'كمية الميكروفون',
      assetPath: 'assets/images/room_mic_level_icon.png',
    ),
    _RoomSettingAction(
      label: 'الاعضاء',
      assetPath: 'assets/images/room_members_setting_icon.png',
    ),
    _RoomSettingAction(
      label: 'مسح الدردشة',
      assetPath: 'assets/images/room_clear_chat_icon.png',
    ),
  ];

  static const List<_RoomSettingAction> _roomModes = [
    _RoomSettingAction(
      label: '1 + 1 رفقة',
      assetPath: 'assets/images/room_mode_companion_icon.png',
    ),
    _RoomSettingAction(
      label: 'Teen Patti',
      assetPath: 'assets/images/room_mode_teen_patti_icon.png',
    ),
    _RoomSettingAction(
      label: 'ludo',
      assetPath: 'assets/images/room_mode_ludo_icon.png',
    ),
    _RoomSettingAction(
      label: 'Carrom',
      assetPath: 'assets/images/room_mode_carrom_icon.png',
    ),
  ];

  static const List<_RoomSettingAction> _moreSettings = [
    _RoomSettingAction(
      label: 'تصغير الشاشة',
      assetPath: 'assets/images/room_minimize_icon.png',
      semanticLabel: 'minimize-room-settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RoomBackgroundView(),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: const SizedBox.expand(),
            ),
          ),
          RoomSettingsBackdrop(
            onGeneralActionTap: (label) {
              if (label == 'اعدادات الغرفة') {
                Navigator.of(context).pushNamed(AppRoutes.roomGeneralSettings);
                return;
              }

              if (label == 'موسيقي') {
                Navigator.of(context).pushNamed(AppRoutes.roomMusicPlaylist);
                return;
              }

              if (label == 'صورة الخلفية') {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.roomBackgroundSelection);
                return;
              }

              if (label == 'كمية الميكروفون') {
                Navigator.of(context).pushNamed(AppRoutes.roomMicQuantity);
                return;
              }

              Navigator.of(context).pushNamed(AppRoutes.bootstrap);
            },
            onRoomModeTap: (_) {
              Navigator.of(context).pushNamed(AppRoutes.bootstrap);
            },
            onMoreActionTap: (label) {
              if (label == 'تصغير الشاشة') {
                Navigator.of(context).pop();
                return;
              }

              Navigator.of(context).pushNamed(AppRoutes.bootstrap);
            },
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
    );
  }
}

class RoomSettingsBackdrop extends StatelessWidget {
  const RoomSettingsBackdrop({
    super.key,
    required this.onGeneralActionTap,
    required this.onRoomModeTap,
    required this.onMoreActionTap,
  });

  final ValueChanged<String> onGeneralActionTap;
  final ValueChanged<String> onRoomModeTap;
  final ValueChanged<String> onMoreActionTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 658,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              RoomSettingsScreen._panelTop,
              RoomSettingsScreen._panelBottom,
            ],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 61, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اعدادات الغرفة العامة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SettingsGrid(
                  actions: RoomSettingsScreen._generalSettings,
                  onActionTap: (action) => onGeneralActionTap(action.label),
                ),
                const SizedBox(height: 26),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'وضع الغرفة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _SettingsGrid(
                  actions: RoomSettingsScreen._roomModes,
                  onActionTap: (action) => onRoomModeTap(action.label),
                ),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اعدادات اكتر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsGrid(
                  actions: RoomSettingsScreen._moreSettings,
                  columns: 1,
                  onActionTap: (action) => onMoreActionTap(action.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGrid extends StatelessWidget {
  const _SettingsGrid({
    required this.actions,
    required this.onActionTap,
    this.columns = 4,
  });

  final List<_RoomSettingAction> actions;
  final ValueChanged<_RoomSettingAction> onActionTap;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: actions.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 18,
        mainAxisSpacing: 20,
        childAspectRatio: columns == 1 ? 4.5 : 0.8,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _RoomSettingOption(
          action: action,
          onTap: () => onActionTap(action),
          alignRight: columns == 1,
        );
      },
    );
  }
}

class _RoomSettingOption extends StatelessWidget {
  const _RoomSettingOption({
    required this.action,
    required this.onTap,
    this.alignRight = false,
  });

  final _RoomSettingAction action;
  final VoidCallback onTap;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: RoomSettingsScreen._seatFill,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            action.assetPath,
            width: 30,
            height: 30,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          action.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final child = alignRight
        ? Align(alignment: Alignment.centerRight, child: content)
        : content;

    return Semantics(
      label: action.semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class RoomSettingsBottomComposer extends StatelessWidget {
  const RoomSettingsBottomComposer({
    super.key,
    required this.onControlTap,
    required this.onMuteTap,
    required this.onChatTap,
    required this.onGiftTap,
    required this.onSendTap,
  });

  final VoidCallback onControlTap;
  final VoidCallback onMuteTap;
  final VoidCallback onChatTap;
  final VoidCallback onGiftTap;
  final VoidCallback onSendTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoomComposerButton(
          semanticLabel: 'room-control',
          assetPath: 'assets/images/room_control_icon.png',
          onTap: onControlTap,
        ),
        const SizedBox(width: 10),
        _RoomComposerButton(
          semanticLabel: 'mute-room',
          assetPath: 'assets/images/room_mute_icon.png',
          onTap: onMuteTap,
        ),
        const SizedBox(width: 10),
        _RoomComposerButton(
          semanticLabel: 'room-chat',
          assetPath: 'assets/images/room_chat_icon.png',
          onTap: onChatTap,
        ),
        const SizedBox(width: 10),
        _RoomComposerButton(
          semanticLabel: 'room-gift',
          assetPath: 'assets/images/room_gift_icon.png',
          onTap: onGiftTap,
        ),
        const Spacer(),
        InkWell(
          onTap: onSendTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            width: 167,
            height: 43,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: RoomSettingsScreen._composerFill,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'محمد كيف حالك طمني عليك ؟',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  'assets/images/room_send_icon.png',
                  width: 21,
                  height: 21,
                  filterQuality: FilterQuality.high,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomComposerButton extends StatelessWidget {
  const _RoomComposerButton({
    required this.semanticLabel,
    required this.assetPath,
    required this.onTap,
  });

  final String semanticLabel;
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17.5),
        child: Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            color: RoomSettingsScreen._primaryBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            assetPath,
            width: 17,
            height: 17,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _RoomSettingAction {
  const _RoomSettingAction({
    required this.label,
    required this.assetPath,
    this.semanticLabel = '',
  });

  final String label;
  final String assetPath;
  final String semanticLabel;
}
