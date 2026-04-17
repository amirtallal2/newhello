import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../controllers/room_session_controller.dart';
import '../widgets/room_background_view.dart';
import '../widgets/room_gift_panel_sheet.dart';
import '../widgets/room_games_sheet.dart';
import '../widgets/room_received_gifts_sheet.dart';
import '../widgets/room_seat_join_requests_sheet.dart';
import '../widgets/room_seat_actions_sheet.dart';

const Color _roomPrimaryBlue = Color(0xFF285F98);
const Color _roomSeatFill = Color(0x809DB2CE);
const Color _roomOverlay = Color(0x80232222);

class RoomScreenArgs {
  const RoomScreenArgs({required this.roomId});

  final int roomId;
}

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, this.roomId = 1});

  final int roomId;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void didUpdateWidget(covariant RoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _loadRoom();
    }
  }

  static const String _noticeText =
      'نصائح ادمنية: سوف يقوم بالتفتيش ادمن 24\n'
      'ساعه سيتم حظر حساب نشر المعلومات المنتهكة\n'
      'لقوانين واللوائح والمعلومات المبتذلة والعنيقة\n'
      'وغيرها من المعلومات السيئة.';

  Future<void> _loadRoom() async {
    try {
      await RoomSessionController.instance.loadRoom(roomId: widget.roomId);
    } catch (_) {}
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RoomBackgroundView(),
          SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 44, 18, 22),
              child: Column(
                children: [
                  _RoomHeader(
                    roomId: widget.roomId,
                    onLeaveTap: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                        return;
                      }

                      navigator.pushReplacementNamed(AppRoutes.home);
                    },
                    onSettingsTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.roomSettings);
                    },
                    onInfoTap: () {
                      showRoomReceivedGiftsSheet(context);
                    },
                  ),
                  const SizedBox(height: 26),
                  ValueListenableBuilder<int>(
                    valueListenable: RoomSessionController.instance.micCount,
                    builder: (context, micCount, _) =>
                        ValueListenableBuilder<int?>(
                          valueListenable: RoomSessionController
                              .instance
                              .pendingMicRequestSeatNumber,
                          builder: (context, pendingSeatNumber, child) =>
                              _RoomSeatsGrid(
                                totalMicCount: micCount,
                                pendingRequestSeatNumber: pendingSeatNumber,
                                onSeatTap: (seatNumber) {
                                  final userRole = RoomSessionController
                                      .instance
                                      .currentUserRole
                                      .value;
                                  final hasPendingRequest =
                                      userRole == RoomUserRole.admin &&
                                      pendingSeatNumber == seatNumber;

                                  if (hasPendingRequest) {
                                    showRoomSeatJoinRequestsSheet(
                                      context,
                                      seatNumber: seatNumber,
                                    );
                                    return;
                                  }

                                  showRoomSeatActionsSheet(
                                    context,
                                    seatNumber: seatNumber,
                                    userRole: userRole,
                                  );
                                },
                              ),
                        ),
                  ),
                  const SizedBox(height: 22),
                  const _RoomNoticeCard(text: _noticeText),
                  const Spacer(),
                  _RoomBottomBar(
                    onMuteTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                    },
                    onGamesTap: () {
                      showRoomGamesSheet(context);
                    },
                    onChatTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                    },
                    onGiftTap: () {
                      showRoomGiftPanelSheet(context);
                    },
                    onSendTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.bootstrap);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.roomId,
    required this.onLeaveTap,
    required this.onSettingsTap,
    required this.onInfoTap,
  });

  final int roomId;
  final VoidCallback onLeaveTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 13,
            child: Row(
              children: [
                _RoomCircleButton(
                  semanticLabel: 'leave-room',
                  onTap: onLeaveTap,
                  assetPath: 'assets/images/room_power_icon.png',
                  size: 40,
                  iconSize: 24,
                ),
                const SizedBox(width: 6),
                _RoomCircleButton(
                  semanticLabel: 'room-settings',
                  onTap: onSettingsTap,
                  assetPath: 'assets/images/room_settings_icon.png',
                  size: 40,
                  iconSize: 28,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ValueListenableBuilder(
              valueListenable: RoomSessionController.instance.room,
              builder: (context, room, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HostAvatar(assetPath: room.hostAvatarAsset),
                    const SizedBox(height: 2),
                    Text(
                      room.hostName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            right: 0,
            top: 13,
            child: _RoomInfoBadge(roomId: roomId, onTap: onInfoTap),
          ),
        ],
      ),
    );
  }
}

class _HostAvatar extends StatelessWidget {
  const _HostAvatar({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _RoomInfoBadge extends StatelessWidget {
  const _RoomInfoBadge({required this.roomId, required this.onTap});

  final int roomId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'room-info-badge',
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder(
                valueListenable: RoomSessionController.instance.room,
                builder: (context, room, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        room.roomTitle,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID:${room.roomCode}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 6),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0x59000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xAA111111),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomSeatsGrid extends StatelessWidget {
  const _RoomSeatsGrid({
    required this.totalMicCount,
    required this.pendingRequestSeatNumber,
    required this.onSeatTap,
  });

  final int totalMicCount;
  final int? pendingRequestSeatNumber;
  final ValueChanged<int> onSeatTap;

  static const Map<int, List<int>> _seatRowsByMicCount = {
    5: [4],
    9: [4, 4],
    12: [1, 5, 5],
    15: [4, 5, 5],
  };

  @override
  Widget build(BuildContext context) {
    final rowCounts =
        _seatRowsByMicCount[totalMicCount] ?? _seatRowsByMicCount[9]!;
    final maxColumns = rowCounts.reduce(
      (value, element) => value > element ? value : element,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 18.0;
        final seatSize =
            ((constraints.maxWidth - (spacing * (maxColumns - 1))) / maxColumns)
                .clamp(48.0, 60.0);
        var nextSeatNumber = 1;

        return Column(
          children: rowCounts.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final rowCount = entry.value;
            final startNumber = nextSeatNumber;
            nextSeatNumber += rowCount;
            final rowNumbers = List<int>.generate(
              rowCount,
              (index) => startNumber + rowCount - index - 1,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex == rowCounts.length - 1 ? 0 : 18,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: rowNumbers
                    .asMap()
                    .entries
                    .map(
                      (seatEntry) => Padding(
                        padding: EdgeInsets.only(
                          right: seatEntry.key == rowNumbers.length - 1
                              ? 0
                              : spacing,
                        ),
                        child: SizedBox(
                          width: seatSize,
                          child: Center(
                            child: _RoomSeat(
                              number: seatEntry.value,
                              size: seatSize,
                              hasPendingRequest:
                                  pendingRequestSeatNumber == seatEntry.value,
                              onTap: () => onSeatTap(seatEntry.value),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RoomSeat extends StatelessWidget {
  const _RoomSeat({
    required this.number,
    required this.size,
    required this.hasPendingRequest,
    required this.onTap,
  });

  final int number;
  final double size;
  final bool hasPendingRequest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.4;
    final numberFontSize = size >= 56 ? 14.0 : 13.0;

    return Semantics(
      container: true,
      label: 'room-seat-$number',
      button: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(size / 2),
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: _roomSeatFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/room_mic_icon.png',
                        width: iconSize,
                        height: iconSize,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    if (hasPendingRequest)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: size * 0.28,
                          height: size * 0.28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF285F98),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.22,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$number',
              style: const TextStyle(
                color: _roomPrimaryBlue,
                fontWeight: FontWeight.w600,
              ).copyWith(fontSize: numberFontSize),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomNoticeCard extends StatelessWidget {
  const _RoomNoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: _roomOverlay,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}

class _RoomBottomBar extends StatelessWidget {
  const _RoomBottomBar({
    required this.onMuteTap,
    required this.onGamesTap,
    required this.onChatTap,
    required this.onGiftTap,
    required this.onSendTap,
  });

  final VoidCallback onMuteTap;
  final VoidCallback onGamesTap;
  final VoidCallback onChatTap;
  final VoidCallback onGiftTap;
  final VoidCallback onSendTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoomCircleButton(
          semanticLabel: 'mute-room',
          onTap: onMuteTap,
          assetPath: 'assets/images/room_mute_icon.png',
          size: 35,
          iconSize: 17,
        ),
        const SizedBox(width: 5),
        _RoomCircleButton(
          semanticLabel: 'room-games',
          onTap: onGamesTap,
          assetPath: 'assets/images/room_games_icon.png',
          size: 35,
          iconSize: 17,
        ),
        const SizedBox(width: 5),
        _RoomCircleButton(
          semanticLabel: 'room-chat',
          onTap: onChatTap,
          assetPath: 'assets/images/room_chat_icon.png',
          size: 35,
          iconSize: 17,
        ),
        const SizedBox(width: 5),
        _RoomCircleButton(
          semanticLabel: 'room-gift',
          onTap: onGiftTap,
          assetPath: 'assets/images/room_gift_icon.png',
          size: 35,
          iconSize: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: onSendTap,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 43,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: _roomOverlay,
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
        ),
      ],
    );
  }
}

class _RoomCircleButton extends StatelessWidget {
  const _RoomCircleButton({
    required this.semanticLabel,
    required this.onTap,
    required this.assetPath,
    required this.size,
    required this.iconSize,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final String assetPath;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: _roomPrimaryBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
