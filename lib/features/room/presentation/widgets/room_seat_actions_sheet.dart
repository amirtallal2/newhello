import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../controllers/room_session_controller.dart';
import 'room_request_mic_sheet.dart';

Future<void> showRoomSeatActionsSheet(
  BuildContext context, {
  required int seatNumber,
  required RoomUserRole userRole,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'room-seat-actions-$seatNumber',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return userRole == RoomUserRole.admin
          ? _RoomSeatActionsDialog(rootContext: context, seatNumber: seatNumber)
          : _RoomMemberSeatActionsDialog(
              rootContext: context,
              seatNumber: seatNumber,
            );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}

class _RoomSeatActionsDialog extends StatelessWidget {
  const _RoomSeatActionsDialog({
    required this.rootContext,
    required this.seatNumber,
  });

  final BuildContext rootContext;
  final int seatNumber;

  static const List<_SeatActionItemData> _actions = [
    _SeatActionItemData(
      label: 'حظر المايك',
      assetPath: 'assets/images/room_ban_mic_icon.png',
      semanticLabel: 'seat-action-ban-mic',
    ),
    _SeatActionItemData(
      label: 'طرد المايك',
      assetPath: 'assets/images/room_kick_mic_icon.png',
      semanticLabel: 'seat-action-kick-mic',
    ),
    _SeatActionItemData(
      label: 'كتم الصوت',
      assetPath: 'assets/images/room_mute_mic_icon.png',
      semanticLabel: 'seat-action-mute-mic',
    ),
    _SeatActionItemData(
      label: 'دعوه لهذه الميك',
      assetPath: 'assets/images/room_invite_this_mic_icon.png',
      semanticLabel: 'seat-action-invite-this-mic',
    ),
    _SeatActionItemData(
      label: 'دعوه شخص ما إلى الميك',
      assetPath: 'assets/images/room_invite_person_mic_icon.png',
      semanticLabel: 'seat-action-invite-person',
    ),
    _SeatActionItemData(
      label: 'بدل هذه المقعد',
      assetPath: 'assets/images/room_swap_seat_icon.png',
      semanticLabel: 'seat-action-swap-seat',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: const Color(0x05FFFFFF)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Semantics(
            label: 'room-seat-actions-$seatNumber',
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 433,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    ..._actions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final action = entry.value;

                      return Column(
                        children: [
                          _SeatActionRow(
                            action: action,
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(
                                rootContext,
                              ).pushNamed(AppRoutes.bootstrap);
                            },
                          ),
                          if (index != _actions.length - 1)
                            const Divider(
                              height: 2,
                              thickness: 2,
                              color: Color(0xFFEBEBEB),
                              indent: 20,
                              endIndent: 20,
                            ),
                        ],
                      );
                    }),
                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Color(0xFFEBEBEB),
                      indent: 20,
                      endIndent: 20,
                    ),
                    _SeatCancelRow(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomMemberSeatActionsDialog extends StatelessWidget {
  const _RoomMemberSeatActionsDialog({
    required this.rootContext,
    required this.seatNumber,
  });

  final BuildContext rootContext;
  final int seatNumber;

  static const _primaryBlue = Color(0xFF285F98);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: const Color(0x05FFFFFF)),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              height: 321,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF7FBAF8), Color(0xFF285F98)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 61, 18, 22),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MemberSeatActionButton(
                              semanticLabel: 'seat-action-cancel-member',
                              label: 'الالغاء',
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            _MemberSeatActionButton(
                              semanticLabel: 'seat-action-share-room',
                              label: 'مشاركة الغرفة',
                              assetPath:
                                  'assets/images/room_share_setting_icon.png',
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(
                                  rootContext,
                                ).pushNamed(AppRoutes.bootstrap);
                              },
                            ),
                            _MemberSeatActionButton(
                              semanticLabel: 'seat-action-music-member',
                              label: 'موسيقي',
                              assetPath:
                                  'assets/images/room_music_setting_icon.png',
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(
                                  rootContext,
                                ).pushNamed(AppRoutes.roomMusicPlaylist);
                              },
                            ),
                            _MemberSeatActionButton(
                              semanticLabel: 'seat-action-report-member',
                              label: 'تقرير',
                              icon: const Icon(
                                Icons.flag_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                Future<void>.delayed(
                                  const Duration(milliseconds: 200),
                                  () {
                                    if (!rootContext.mounted) {
                                      return;
                                    }

                                    Navigator.of(
                                      rootContext,
                                    ).pushNamed(AppRoutes.roomReport);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _MemberRequestMicCard(
                            seatNumber: seatNumber,
                            onTap: () {
                              Navigator.of(context).pop();
                              Future<void>.delayed(
                                const Duration(milliseconds: 200),
                                () {
                                  if (!rootContext.mounted) {
                                    return;
                                  }

                                  showRoomRequestMicSheet(
                                    rootContext,
                                    seatNumber: seatNumber,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeatActionRow extends StatelessWidget {
  const _SeatActionRow({required this.action, required this.onTap});

  final _SeatActionItemData action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: action.semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Stack(
            children: [
              Center(
                child: Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              PositionedDirectional(
                end: 112,
                top: 13,
                child: Image.asset(
                  action.assetPath,
                  width: 30,
                  height: 30,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatCancelRow extends StatelessWidget {
  const _SeatCancelRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'seat-action-cancel',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          height: 71,
          child: Center(
            child: Text(
              'الغاء',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatActionItemData {
  const _SeatActionItemData({
    required this.label,
    required this.assetPath,
    required this.semanticLabel,
  });

  final String label;
  final String assetPath;
  final String semanticLabel;
}

class _MemberSeatActionButton extends StatelessWidget {
  const _MemberSeatActionButton({
    required this.semanticLabel,
    required this.label,
    required this.onTap,
    this.assetPath,
    this.icon,
  });

  final String semanticLabel;
  final String label;
  final VoidCallback onTap;
  final String? assetPath;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0x809DB2CE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: assetPath != null
                      ? Image.asset(
                          assetPath!,
                          width: 30,
                          height: 30,
                          filterQuality: FilterQuality.high,
                        )
                      : icon,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
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
      ),
    );
  }
}

class _MemberRequestMicCard extends StatelessWidget {
  const _MemberRequestMicCard({required this.seatNumber, required this.onTap});

  final int seatNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'seat-action-request-mic',
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0x809DB2CE),
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/profile_avatar.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: _RoomMemberSeatActionsDialog._primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Nada',
                style: TextStyle(
                  color: _RoomMemberSeatActionsDialog._primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'طلب المايك',
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
    );
  }
}
