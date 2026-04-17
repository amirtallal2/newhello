import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../widgets/room_background_view.dart';

class RoomGeneralSettingsScreen extends StatelessWidget {
  const RoomGeneralSettingsScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _panelBlue = Color(0xFF285F98);
  static const Color _modalTop = Color(0xFF86BEF8);
  static const Color _modalBottom = Color(0xFF285F98);
  static const Color _fieldStart = Color(0xFF285F98);
  static const Color _fieldEnd = Color(0xFF0B83FF);
  static const Color _successGreen = Color(0xFF34A853);
  static const Color _saveGreen = Color(0xFF1F9254);
  static const Color _seatFill = Color(0x809DB2CE);
  static const Color _composerFill = Color(0x80232222);

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
              onActionTap: (label) {
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

                if (label == 'اعدادات الغرفة') {
                  return;
                }

                Navigator.of(context).pushNamed(AppRoutes.bootstrap);
              },
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                Positioned(
                  top: 61,
                  right: 17,
                  child: const Text(
                    'اعدادات الغرفة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 175,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 332),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 22),
                        child: _GeneralSettingsModal(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 18,
                  bottom: 22,
                  child: _BottomComposer(
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

class RoomGeneralSettingsBackdropPanel extends StatelessWidget {
  const RoomGeneralSettingsBackdropPanel({
    super.key,
    required this.onActionTap,
  });

  final ValueChanged<String> onActionTap;

  static const _actions = [
    _BackdropAction(
      label: 'اعدادات الغرفة',
      assetPath: 'assets/images/room_general_settings_icon.png',
    ),
    _BackdropAction(
      label: 'موسيقي',
      assetPath: 'assets/images/room_music_setting_icon.png',
    ),
    _BackdropAction(
      label: 'صورة الخلفية',
      assetPath: 'assets/images/room_background_setting_icon.png',
    ),
    _BackdropAction(
      label: 'قفل الغرفة',
      assetPath: 'assets/images/room_lock_setting_icon.png',
    ),
    _BackdropAction(
      label: 'اغلق الشاشة\nالعامة',
      assetPath: 'assets/images/room_hide_screen_icon.png',
    ),
    _BackdropAction(
      label: 'دردشة واضحة',
      assetPath: 'assets/images/room_clear_chat_mode_icon.png',
    ),
    _BackdropAction(
      label: 'اعداد الدردشة',
      assetPath: 'assets/images/room_chat_setup_icon.png',
    ),
    _BackdropAction(
      label: 'كمية الميكروفون',
      assetPath: 'assets/images/room_mic_level_icon.png',
    ),
    _BackdropAction(
      label: '1 + 1 رفقة',
      assetPath: 'assets/images/room_mode_companion_icon.png',
    ),
    _BackdropAction(
      label: 'Teen Patti',
      assetPath: 'assets/images/room_mode_teen_patti_icon.png',
    ),
    _BackdropAction(
      label: 'ludo',
      assetPath: 'assets/images/room_mode_ludo_icon.png',
    ),
    _BackdropAction(
      label: 'Carrom',
      assetPath: 'assets/images/room_mode_carrom_icon.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 577,
      color: RoomGeneralSettingsScreen._panelBlue,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 332),
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              children: [
                _BackdropActionGrid(
                  actions: _actions.sublist(0, 8),
                  onActionTap: onActionTap,
                ),
                const SizedBox(height: 88),
                _BackdropActionGrid(
                  actions: _actions.sublist(8, 12),
                  onActionTap: onActionTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropActionGrid extends StatelessWidget {
  const _BackdropActionGrid({required this.actions, required this.onActionTap});

  final List<_BackdropAction> actions;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 30,
      runSpacing: 20,
      children: actions
          .map(
            (action) => SizedBox(
              width: 60,
              child: InkWell(
                key: ValueKey('room-backdrop-action-${action.label}'),
                onTap: () => onActionTap(action.label),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: RoomGeneralSettingsScreen._seatFill,
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
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _GeneralSettingsModal extends StatelessWidget {
  const _GeneralSettingsModal();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RoomGeneralSettingsScreen._modalTop,
            RoomGeneralSettingsScreen._modalBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            'اعدادات الغرفة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          _FieldBlock(
            label: 'اسم الغرفة',
            child: _GradientField(text: 'غرفة محمد احمد'),
          ),
          SizedBox(height: 10),
          _FieldBlock(
            label: 'نوع الغرفة',
            child: _GradientField(text: 'دردشة عامة'),
          ),
          SizedBox(height: 10),
          _FieldBlock(label: 'شعار الغرفة', child: _LogoField()),
          SizedBox(height: 10),
          _FieldBlock(
            label: 'ايدي الغرفة',
            child: _GradientField(text: '54648121'),
          ),
          SizedBox(height: 10),
          _FieldBlock(
            label: 'قائمة الحظر',
            child: _GradientField(text: 'لا يوجد حظر الان'),
          ),
          SizedBox(height: 10),
          _FieldBlock(
            label: 'المايكات',
            secondaryLabel: 'ادمن',
            child: _MicrophonesAdminRow(),
          ),
          SizedBox(height: 30),
          _SaveButton(),
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.child,
    this.secondaryLabel,
  });

  final String label;
  final String? secondaryLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (secondaryLabel != null)
              Text(
                secondaryLabel!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const SizedBox(width: 1),
            Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _GradientField extends StatelessWidget {
  const _GradientField({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 33,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            RoomGeneralSettingsScreen._fieldStart,
            RoomGeneralSettingsScreen._fieldEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LogoField extends StatelessWidget {
  const _LogoField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            RoomGeneralSettingsScreen._fieldStart,
            RoomGeneralSettingsScreen._fieldEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/room_logo_plus_icon.png',
                width: 20,
                height: 20,
                filterQuality: FilterQuality.high,
              ),
              const Text(
                '+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'Photo.PNG',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _MicrophonesAdminRow extends StatelessWidget {
  const _MicrophonesAdminRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 33,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  RoomGeneralSettingsScreen._fieldStart,
                  RoomGeneralSettingsScreen._fieldEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ادمن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Image.asset(
                    'assets/images/room_admin_icon.png',
                    width: 21,
                    height: 21,
                    filterQuality: FilterQuality.high,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            height: 33,
            decoration: BoxDecoration(
              color: RoomGeneralSettingsScreen._successGreen,
              borderRadius: BorderRadius.circular(5),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/room_small_mic_icon.png',
                    width: 15,
                    height: 15,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'تشغيل المايكات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 33,
        decoration: BoxDecoration(
          color: RoomGeneralSettingsScreen._saveGreen,
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
    );
  }
}

class _BottomComposer extends StatelessWidget {
  const _BottomComposer({
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
        _ComposerButton(
          assetPath: 'assets/images/room_control_icon.png',
          onTap: onControlTap,
        ),
        const SizedBox(width: 10),
        _ComposerButton(
          assetPath: 'assets/images/room_mute_icon.png',
          onTap: onMuteTap,
        ),
        const SizedBox(width: 10),
        _ComposerButton(
          assetPath: 'assets/images/room_chat_icon.png',
          onTap: onChatTap,
        ),
        const SizedBox(width: 10),
        _ComposerButton(
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
              color: RoomGeneralSettingsScreen._composerFill,
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

class _ComposerButton extends StatelessWidget {
  const _ComposerButton({required this.assetPath, required this.onTap});

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17.5),
      child: Container(
        width: 35,
        height: 35,
        decoration: const BoxDecoration(
          color: RoomGeneralSettingsScreen._primaryBlue,
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
    );
  }
}

class _BackdropAction {
  const _BackdropAction({required this.label, required this.assetPath});

  final String label;
  final String assetPath;
}
