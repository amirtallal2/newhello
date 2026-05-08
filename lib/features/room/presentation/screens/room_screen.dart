import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../data/room_audio_repository.dart';
import '../controllers/room_audio_controller.dart';
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
  bool _isClosingRoom = false;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void dispose() {
    RoomAudioController.instance.disconnect();
    super.dispose();
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
      await RoomAudioController.instance.connect(widget.roomId);
    } catch (_) {}
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMuteTap() {
    RoomAudioController.instance.toggleMicrophone();
  }

  bool get _isCurrentUserRoomHost {
    final audioRole = RoomAudioController.instance.session.value?.role;
    return audioRole == RoomAudioParticipantRole.host ||
        RoomSessionController.instance.currentUserRole.value ==
            RoomUserRole.admin;
  }

  Future<void> _handleLeaveTap() async {
    if (_isClosingRoom) {
      return;
    }

    if (_isCurrentUserRoomHost) {
      final shouldEnd = await _confirmEndAudioRoom();
      if (shouldEnd != true || !mounted) {
        return;
      }

      setState(() {
        _isClosingRoom = true;
      });

      try {
        await RoomAudioRepository.instance.endRoom(widget.roomId);
        await RoomAudioController.instance.disconnect(
          sendLeaveToBackend: false,
        );
        if (!mounted) {
          return;
        }
        _navigateAway();
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isClosingRoom = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      return;
    }

    setState(() {
      _isClosingRoom = true;
    });
    await RoomAudioController.instance.disconnect();
    if (!mounted) {
      return;
    }
    _navigateAway();
  }

  Future<bool?> _confirmEndAudioRoom() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء الغرفة الصوتية؟'),
        content: const Text(
          'أنت صاحب الغرفة. إغلاقها سيخرج كل الموجودين ويخفيها من قائمة الغرف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('إنهاء للجميع'),
          ),
        ],
      ),
    );
  }

  void _navigateAway() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(AppRoutes.home);
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
                    onLeaveTap: _handleLeaveTap,
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
                        ValueListenableBuilder<List<RoomAudioParticipantData>>(
                          valueListenable:
                              RoomAudioController.instance.participants,
                          builder: (context, audioParticipants, child) =>
                              ValueListenableBuilder<Set<String>>(
                                valueListenable: RoomAudioController
                                    .instance
                                    .speakingUserAccounts,
                                builder:
                                    (
                                      context,
                                      speakingUserAccounts,
                                      child,
                                    ) => ValueListenableBuilder<int?>(
                                      valueListenable: RoomSessionController
                                          .instance
                                          .pendingMicRequestSeatNumber,
                                      builder:
                                          (
                                            context,
                                            pendingSeatNumber,
                                            child,
                                          ) => _RoomSeatsGrid(
                                            totalMicCount: micCount,
                                            pendingRequestSeatNumber:
                                                pendingSeatNumber,
                                            participants: audioParticipants,
                                            speakingUserAccounts:
                                                speakingUserAccounts,
                                            onSeatTap: (seatNumber) {
                                              final userRole =
                                                  RoomSessionController
                                                      .instance
                                                      .currentUserRole
                                                      .value;
                                              final hasPendingRequest =
                                                  userRole ==
                                                      RoomUserRole.admin &&
                                                  pendingSeatNumber ==
                                                      seatNumber;

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
                        ),
                  ),
                  const SizedBox(height: 22),
                  const _RoomNoticeCard(text: _noticeText),
                  const SizedBox(height: 12),
                  const _RoomAudioStatusCard(),
                  const Spacer(),
                  ValueListenableBuilder<RoomAudioSessionData?>(
                    valueListenable: RoomAudioController.instance.session,
                    builder: (context, audioSession, _) {
                      return _RoomBottomBar(
                        isMicMuted: audioSession?.micMuted ?? true,
                        canToggleMicrophone:
                            audioSession?.canPublishMicrophone ?? false,
                        onMuteTap: _handleMuteTap,
                        onGamesTap: () {
                          showRoomGamesSheet(context, roomId: widget.roomId);
                        },
                        onChatTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.chatMessages);
                        },
                        onGiftTap: () {
                          showRoomGiftPanelSheet(context);
                        },
                        onSendTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.chatMessages);
                        },
                      );
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
                return ValueListenableBuilder<List<RoomAudioParticipantData>>(
                  valueListenable: RoomAudioController.instance.participants,
                  builder: (context, participants, _) {
                    final hostParticipant = _findHostParticipant(participants);
                    return ValueListenableBuilder<Set<String>>(
                      valueListenable:
                          RoomAudioController.instance.speakingUserAccounts,
                      builder: (context, speakingUserAccounts, _) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HostAvatar(
                              assetPath: room.hostAvatarAsset,
                              isSpeaking:
                                  hostParticipant != null &&
                                  speakingUserAccounts.contains(
                                    hostParticipant.userAccount,
                                  ),
                            ),
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
                    );
                  },
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
  const _HostAvatar({required this.assetPath, required this.isSpeaking});

  final String assetPath;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    return _SpeakingAvatarFrame(
      size: 66,
      isSpeaking: isSpeaking,
      child: Container(
        width: 66,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ResolvedImage(
          path: assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
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
                  return ValueListenableBuilder<List<RoomAudioParticipantData>>(
                    valueListenable: RoomAudioController.instance.participants,
                    builder: (context, audioParticipants, _) {
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
                            'ID:${room.roomCode} • ${audioParticipants.length} live',
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
    required this.participants,
    required this.speakingUserAccounts,
    required this.onSeatTap,
  });

  final int totalMicCount;
  final int? pendingRequestSeatNumber;
  final List<RoomAudioParticipantData> participants;
  final Set<String> speakingUserAccounts;
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
    final occupantsBySeat = <int, RoomAudioParticipantData>{
      for (final participant in participants)
        if (participant.seatNumber != null)
          participant.seatNumber!: participant,
    };
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
                              participant: occupantsBySeat[seatEntry.value],
                              isSpeaking:
                                  occupantsBySeat[seatEntry.value] != null &&
                                  speakingUserAccounts.contains(
                                    occupantsBySeat[seatEntry.value]!
                                        .userAccount,
                                  ),
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
    required this.participant,
    required this.isSpeaking,
    required this.hasPendingRequest,
    required this.onTap,
  });

  final int number;
  final double size;
  final RoomAudioParticipantData? participant;
  final bool isSpeaking;
  final bool hasPendingRequest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.4;
    final numberFontSize = size >= 56 ? 14.0 : 13.0;
    final occupant = participant;

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
              child: _SpeakingAvatarFrame(
                size: size,
                isSpeaking:
                    occupant != null && isSpeaking && !occupant.micMuted,
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
                      if (occupant == null)
                        Center(
                          child: Image.asset(
                            'assets/images/room_mic_icon.png',
                            width: iconSize,
                            height: iconSize,
                            filterQuality: FilterQuality.high,
                          ),
                        )
                      else
                        ClipOval(
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: ResolvedImage(
                              path: occupant.avatarAsset,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      if (occupant != null)
                        Positioned(
                          left: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: occupant.micMuted
                                  ? const Color(0xCC9F2D2D)
                                  : const Color(0xCC285F98),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              occupant.role == RoomAudioParticipantRole.host
                                  ? 'H'
                                  : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
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
                      if (occupant != null && occupant.micMuted)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: size * 0.22,
                            height: size * 0.22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE95B5B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              occupant?.displayName ?? '$number',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _roomPrimaryBlue,
                fontWeight: FontWeight.w600,
              ).copyWith(fontSize: occupant == null ? numberFontSize : 10),
            ),
          ],
        ),
      ),
    );
  }
}

RoomAudioParticipantData? _findHostParticipant(
  List<RoomAudioParticipantData> participants,
) {
  for (final participant in participants) {
    if (participant.role == RoomAudioParticipantRole.host) {
      return participant;
    }
  }
  return null;
}

class _SpeakingAvatarFrame extends StatefulWidget {
  const _SpeakingAvatarFrame({
    required this.size,
    required this.isSpeaking,
    required this.child,
  });

  final double size;
  final bool isSpeaking;
  final Widget child;

  @override
  State<_SpeakingAvatarFrame> createState() => _SpeakingAvatarFrameState();
}

class _SpeakingAvatarFrameState extends State<_SpeakingAvatarFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _SpeakingAvatarFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSpeaking != widget.isSpeaking) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isSpeaking) {
      _controller.repeat(reverse: true);
      return;
    }

    _controller.stop();
    _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpeaking) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = Curves.easeInOut.transform(_controller.value);
        final glowColor = _roomPrimaryBlue.withValues(
          alpha: 0.22 + (progress * 0.18),
        );

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + (progress * 0.08),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: glowColor,
                    width: 2 + (progress * 1.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 14 + (progress * 8),
                      spreadRadius: 1 + (progress * 2),
                    ),
                  ],
                ),
              ),
            ),
            child!,
            Positioned(
              bottom: -8,
              child: _SpeakingBars(
                size: widget.size * 0.26,
                progress: progress,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpeakingBars extends StatelessWidget {
  const _SpeakingBars({required this.size, required this.progress});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final heights = <double>[
      0.45 + (progress * 0.45),
      0.8 - (progress * 0.25),
      0.35 + (progress * 0.55),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6285F98),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  right: entry.key == heights.length - 1 ? 0 : 2,
                ),
                child: Container(
                  width: size * 0.16,
                  height: size * entry.value,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
            .toList(),
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

class _RoomAudioStatusCard extends StatelessWidget {
  const _RoomAudioStatusCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RoomAudioConnectionState>(
      valueListenable: RoomAudioController.instance.connectionState,
      builder: (context, state, _) {
        return ValueListenableBuilder<RoomAudioSessionData?>(
          valueListenable: RoomAudioController.instance.session,
          builder: (context, audioSession, child) {
            return ValueListenableBuilder<String?>(
              valueListenable: RoomAudioController.instance.statusMessage,
              builder: (context, message, innerChild) {
                final title = switch (state) {
                  RoomAudioConnectionState.connecting =>
                    'جارٍ ربط الصوت المباشر',
                  RoomAudioConnectionState.disabled => 'الصوت المباشر مغلق',
                  RoomAudioConnectionState.notConfigured =>
                    'إعدادات Agora غير مكتملة',
                  RoomAudioConnectionState.permissionDenied =>
                    'إذن الميكروفون مطلوب',
                  RoomAudioConnectionState.joined =>
                    audioSession == null
                        ? 'الغرفة الصوتية متصلة'
                        : audioSession.canPublishMicrophone
                        ? (audioSession.micMuted
                              ? 'الميكروفون مغلق الآن'
                              : 'الميكروفون يعمل الآن')
                        : 'أنت داخل الغرفة كمستمع',
                  RoomAudioConnectionState.error => 'تعذر تشغيل الصوت المباشر',
                  RoomAudioConnectionState.idle => '',
                };

                final body = switch (state) {
                  RoomAudioConnectionState.joined =>
                    audioSession == null
                        ? ''
                        : 'Channel: ${audioSession.channelName} • Participants: ${audioSession.participants.length}',
                  _ => message ?? '',
                };

                if (title.isEmpty) {
                  return const SizedBox.shrink();
                }

                final Color backgroundColor = switch (state) {
                  RoomAudioConnectionState.joined => const Color(0x99285F98),
                  RoomAudioConnectionState.connecting => const Color(
                    0x997C8AA3,
                  ),
                  _ => const Color(0x99A35C2D),
                };

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RoomBottomBar extends StatelessWidget {
  const _RoomBottomBar({
    required this.isMicMuted,
    required this.canToggleMicrophone,
    required this.onMuteTap,
    required this.onGamesTap,
    required this.onChatTap,
    required this.onGiftTap,
    required this.onSendTap,
  });

  final bool isMicMuted;
  final bool canToggleMicrophone;
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
          backgroundColor: canToggleMicrophone
              ? (isMicMuted ? const Color(0xFF7C8AA3) : const Color(0xFF1F8A5B))
              : _roomPrimaryBlue,
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
    this.backgroundColor = _roomPrimaryBlue,
    required this.size,
    required this.iconSize,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final String assetPath;
  final Color backgroundColor;
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
          decoration: BoxDecoration(
            color: backgroundColor,
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
