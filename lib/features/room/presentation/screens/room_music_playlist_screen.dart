import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../data/room_music_repository.dart';
import '../controllers/room_session_controller.dart';
import '../widgets/room_background_view.dart';
import '../widgets/room_gift_panel_sheet.dart';

class RoomMusicPlaylistScreen extends StatefulWidget {
  const RoomMusicPlaylistScreen({super.key});

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _seatFill = Color(0x809DB2CE);
  static const Color _overlay = Color(0x80232222);
  static const Color _emptySheetBackground = Color(0xFF9DB2CE);

  @override
  State<RoomMusicPlaylistScreen> createState() =>
      _RoomMusicPlaylistScreenState();
}

class _RoomMusicPlaylistScreenState extends State<RoomMusicPlaylistScreen> {
  static const String _noticeText =
      'نصائح ادمنية: سوف يقوم بالتفتيش ادمن 24\n'
      'ساعه سيتم حظر حساب نشر المعلومات المنتهكة\n'
      'لقوانين واللوائح والمعلومات المبتذلة والعنيقة\n'
      'وغيرها من المعلومات السيئة.';

  _RoomMusicFlowStage _stage = _RoomMusicFlowStage.emptyPlaylist;
  bool _isPlaylistLoading = true;
  bool _isSourceActionRunning = false;
  RoomMusicPlaylistData _playlistData = const RoomMusicPlaylistData(
    roomId: 1,
    entries: <RoomMusicPlaylistEntryData>[],
  );

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    try {
      final playlist = await RoomMusicRepository.instance.loadPlaylist(
        roomId: RoomSessionController.instance.activeRoomId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _playlistData = playlist;
        _isPlaylistLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaylistLoading = false;
      });
    }
  }

  void _closeCurrentLayer() {
    if (_stage == _RoomMusicFlowStage.sourcePicker) {
      setState(() {
        _stage = _RoomMusicFlowStage.emptyPlaylist;
      });
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(AppRoutes.roomSettings);
  }

  void _openSourcePicker() {
    setState(() {
      _stage = _RoomMusicFlowStage.sourcePicker;
    });
  }

  Future<void> _addTrackFromSource(RoomMusicSourceType sourceType) async {
    if (_isSourceActionRunning) {
      return;
    }

    setState(() {
      _isSourceActionRunning = true;
    });

    try {
      final playlist = await RoomMusicRepository.instance.addFirstTrackFromSource(
        roomId: RoomSessionController.instance.activeRoomId,
        sourceType: sourceType,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _playlistData = playlist;
        _stage = _RoomMusicFlowStage.emptyPlaylist;
        _isSourceActionRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة موسيقى ${sourceType.label}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSourceActionRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _removeTrack(int playlistEntryId) async {
    final playlist = await RoomMusicRepository.instance.removeTrack(
      roomId: RoomSessionController.instance.activeRoomId,
      playlistEntryId: playlistEntryId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _playlistData = playlist;
    });
  }

  void _openRoomSettings() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(AppRoutes.roomSettings);
  }

  void _leaveRoom() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isSourcePicker = _stage == _RoomMusicFlowStage.sourcePicker;
    final hasEntries = _playlistData.entries.isNotEmpty;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RoomBackgroundView(),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isSourcePicker ? 25 : 2,
                sigmaY: isSourcePicker ? 25 : 2,
              ),
              child: Container(
                color: isSourcePicker
                    ? const Color(0x2EFFFFFF)
                    : const Color(0x05FFFFFF),
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                if (isSourcePicker) ...[
                  Positioned(
                    left: 19,
                    top: 90,
                    child: Row(
                      children: [
                        _MusicCircleButton(
                          semanticLabel: 'music-room-leave',
                          onTap: _leaveRoom,
                          assetPath: 'assets/images/room_power_icon.png',
                          size: 40,
                          iconSize: 24,
                        ),
                        const SizedBox(width: 6),
                        _MusicCircleButton(
                          semanticLabel: 'music-room-settings',
                          onTap: _openRoomSettings,
                          assetPath: 'assets/images/room_settings_icon.png',
                          size: 40,
                          iconSize: 28,
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 7,
                    top: 90,
                    child: _MusicRoomInfoBadge(),
                  ),
                ],
                const Positioned(
                  top: 77,
                  left: 0,
                  right: 0,
                  child: _MusicHostHeader(),
                ),
                Positioned(
                  top: 180,
                  left: 23,
                  right: 22,
                  child: ValueListenableBuilder<int>(
                    valueListenable: RoomSessionController.instance.micCount,
                    builder: (context, micCount, _) =>
                        _MusicSeatsGrid(totalMicCount: micCount),
                  ),
                ),
                const Positioned(
                  top: 369,
                  left: 18,
                  right: 18,
                  child: _MusicNoticeCard(text: _noticeText),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: isSourcePicker
                      ? _MusicSourceSelectionSheet(
                          onHandleTap: _closeCurrentLayer,
                          onWhatsAppTap: () =>
                              _addTrackFromSource(RoomMusicSourceType.whatsapp),
                          onFriendsTap: () =>
                              _addTrackFromSource(RoomMusicSourceType.friends),
                          onMuteTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.bootstrap);
                          },
                          onChatTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.bootstrap);
                          },
                          onGiftTap: () {
                            showRoomGiftPanelSheet(context);
                          },
                          onSendTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.bootstrap);
                          },
                        )
                      : _isPlaylistLoading
                      ? _MusicPlaylistLoadingSheet(onHandleTap: _closeCurrentLayer)
                      : hasEntries
                      ? _MusicPlaylistListSheet(
                          entries: _playlistData.entries,
                          onHandleTap: _closeCurrentLayer,
                          onAddMusicTap: _openSourcePicker,
                          onRemoveTap: _removeTrack,
                        )
                      : _MusicPlaylistSheet(
                          onHandleTap: _closeCurrentLayer,
                          onAddMusicTap: _openSourcePicker,
                        ),
                ),
                if (_isSourceActionRunning)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33000000),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
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

enum _RoomMusicFlowStage { emptyPlaylist, sourcePicker }

class _MusicHostHeader extends StatelessWidget {
  const _MusicHostHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MusicHostAvatar(),
        SizedBox(height: 2),
        Text(
          'محمد احمد',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MusicHostAvatar extends StatelessWidget {
  const _MusicHostAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: const DecorationImage(
          image: AssetImage('assets/images/profile_avatar.png'),
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

class _MusicRoomInfoBadge extends StatelessWidget {
  const _MusicRoomInfoBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(height: 6),
            Text(
              'اريد ان اسمع صوتك',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'ID:1512345412',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: AssetImage('assets/images/profile_avatar.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

class _MusicSeatsGrid extends StatelessWidget {
  const _MusicSeatsGrid({required this.totalMicCount});

  final int totalMicCount;

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
        const spacing = 30.0;
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
                            child: _MusicSeat(
                              number: seatEntry.value,
                              size: seatSize,
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

class _MusicSeat extends StatelessWidget {
  const _MusicSeat({required this.number, required this.size});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.4;
    final numberFontSize = size >= 56 ? 14.0 : 13.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: RoomMusicPlaylistScreen._seatFill,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/room_mic_icon.png',
            width: iconSize,
            height: iconSize,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$number',
          style: const TextStyle(
            color: RoomMusicPlaylistScreen._primaryBlue,
            fontWeight: FontWeight.w600,
          ).copyWith(fontSize: numberFontSize),
        ),
      ],
    );
  }
}

class _MusicNoticeCard extends StatelessWidget {
  const _MusicNoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: RoomMusicPlaylistScreen._overlay,
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

class _MusicPlaylistSheet extends StatelessWidget {
  const _MusicPlaylistSheet({
    required this.onHandleTap,
    required this.onAddMusicTap,
  });

  final VoidCallback onHandleTap;
  final VoidCallback onAddMusicTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'room-music-playlist-sheet',
      child: Container(
        height: 354,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: RoomMusicPlaylistScreen._emptySheetBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            InkWell(
              key: const ValueKey('room-music-playlist-handle'),
              onTap: onHandleTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 141,
                height: 7,
                decoration: BoxDecoration(
                  color: RoomMusicPlaylistScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'قائمة تشغيل فارغة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 42),
            InkWell(
              key: const ValueKey('room-music-add-button'),
              onTap: onAddMusicTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 266,
                height: 57,
                decoration: BoxDecoration(
                  color: RoomMusicPlaylistScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'اضافة الموسيقي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicPlaylistLoadingSheet extends StatelessWidget {
  const _MusicPlaylistLoadingSheet({required this.onHandleTap});

  final VoidCallback onHandleTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'room-music-playlist-sheet',
      child: Container(
        height: 354,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: RoomMusicPlaylistScreen._emptySheetBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            InkWell(
              onTap: onHandleTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 141,
                height: 7,
                decoration: BoxDecoration(
                  color: RoomMusicPlaylistScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicPlaylistListSheet extends StatelessWidget {
  const _MusicPlaylistListSheet({
    required this.entries,
    required this.onHandleTap,
    required this.onAddMusicTap,
    required this.onRemoveTap,
  });

  final List<RoomMusicPlaylistEntryData> entries;
  final VoidCallback onHandleTap;
  final VoidCallback onAddMusicTap;
  final ValueChanged<int> onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'room-music-playlist-sheet',
      child: Container(
        height: 354,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: RoomMusicPlaylistScreen._emptySheetBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            InkWell(
              key: const ValueKey('room-music-playlist-handle'),
              onTap: onHandleTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 141,
                height: 7,
                decoration: BoxDecoration(
                  color: RoomMusicPlaylistScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'قائمة التشغيل',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entries.length} مقطع',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _MusicPlaylistEntryCard(
                    entry: entry,
                    onRemoveTap: () => onRemoveTap(entry.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: InkWell(
                key: const ValueKey('room-music-add-button'),
                onTap: onAddMusicTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: RoomMusicPlaylistScreen._primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'اضافة الموسيقي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicPlaylistEntryCard extends StatelessWidget {
  const _MusicPlaylistEntryCard({
    required this.entry,
    required this.onRemoveTap,
  });

  final RoomMusicPlaylistEntryData entry;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          InkWell(
            key: ValueKey('room-music-remove-${entry.id}'),
            onTap: onRemoveTap,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                color: RoomMusicPlaylistScreen._primaryBlue,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: RoomMusicPlaylistScreen._primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.artistName} • ${entry.sourceType.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF5D6F86),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.durationLabel,
                  style: const TextStyle(
                    color: RoomMusicPlaylistScreen._primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              entry.coverAsset,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicSourceSelectionSheet extends StatelessWidget {
  const _MusicSourceSelectionSheet({
    required this.onHandleTap,
    required this.onWhatsAppTap,
    required this.onFriendsTap,
    required this.onMuteTap,
    required this.onChatTap,
    required this.onGiftTap,
    required this.onSendTap,
  });

  final VoidCallback onHandleTap;
  final VoidCallback onWhatsAppTap;
  final VoidCallback onFriendsTap;
  final VoidCallback onMuteTap;
  final VoidCallback onChatTap;
  final VoidCallback onGiftTap;
  final VoidCallback onSendTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'room-music-source-sheet',
      child: Container(
        height: 101,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 5,
              left: 117,
              child: InkWell(
                key: const ValueKey('room-music-source-picker-handle'),
                onTap: onHandleTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 141,
                  height: 7,
                  decoration: BoxDecoration(
                    color: RoomMusicPlaylistScreen._primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 22,
              child: _MusicSourceOption(
                buttonKey: const ValueKey('room-music-source-whatsapp'),
                label: 'واتساب',
                backgroundColor: const Color(0xFF51B05F),
                assetPath: 'assets/images/room_music_whatsapp_icon.png',
                onTap: onWhatsAppTap,
              ),
            ),
            Positioned(
              right: 88,
              top: 22,
              child: _MusicSourceOption(
                buttonKey: const ValueKey('room-music-source-friends'),
                label: 'الاصدقاء',
                backgroundColor: const Color(0xFFF1BC19),
                assetPath: 'assets/images/room_music_friends_icon.png',
                onTap: onFriendsTap,
                iconSize: 30,
              ),
            ),
            Positioned(
              left: 18,
              top: 38,
              child: Row(
                children: [
                  _MusicCircleButton(
                    semanticLabel: 'music-sheet-mute',
                    onTap: onMuteTap,
                    assetPath: 'assets/images/room_mute_icon.png',
                    size: 35,
                    iconSize: 17,
                  ),
                  const SizedBox(width: 10),
                  _MusicCircleButton(
                    semanticLabel: 'music-sheet-chat',
                    onTap: onChatTap,
                    assetPath: 'assets/images/room_chat_icon.png',
                    size: 35,
                    iconSize: 17,
                  ),
                  const SizedBox(width: 10),
                  _MusicCircleButton(
                    semanticLabel: 'music-sheet-gift',
                    onTap: onGiftTap,
                    assetPath: 'assets/images/room_gift_icon.png',
                    size: 35,
                    iconSize: 17,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 161,
              top: 36,
              right: 18,
              child: InkWell(
                onTap: onSendTap,
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 43,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: RoomMusicPlaylistScreen._overlay,
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
        ),
      ),
    );
  }
}

class _MusicSourceOption extends StatelessWidget {
  const _MusicSourceOption({
    this.buttonKey,
    required this.label,
    required this.backgroundColor,
    required this.assetPath,
    required this.onTap,
    this.iconSize = 20,
  });

  final Key? buttonKey;
  final String label;
  final Color backgroundColor;
  final String assetPath;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          _MusicCircleButton(
            semanticLabel: label,
            onTap: onTap,
            assetPath: assetPath,
            size: 40,
            iconSize: iconSize,
            backgroundColor: backgroundColor,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicCircleButton extends StatelessWidget {
  const _MusicCircleButton({
    required this.semanticLabel,
    required this.onTap,
    required this.assetPath,
    required this.size,
    required this.iconSize,
    this.backgroundColor = RoomMusicPlaylistScreen._primaryBlue,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final String assetPath;
  final double size;
  final double iconSize;
  final Color backgroundColor;

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
