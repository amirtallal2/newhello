import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/resolved_image.dart';
import '../../../social/data/social_repository.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/live_repository.dart';

class LiveRoomScreenArgs {
  const LiveRoomScreenArgs({required this.roomId});

  final int roomId;
}

class LiveRoomScreen extends StatefulWidget {
  const LiveRoomScreen({super.key, required this.args});

  final LiveRoomScreenArgs args;

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _accentRed = Color(0xFFF01F38);

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomDataScope extends InheritedWidget {
  const _LiveRoomDataScope({required this.data, required super.child});

  final LiveRoomDetailsData data;

  static LiveRoomDetailsData of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_LiveRoomDataScope>();
    assert(scope != null, 'LiveRoomDataScope is missing in the widget tree.');
    return scope!.data;
  }

  @override
  bool updateShouldNotify(_LiveRoomDataScope oldWidget) =>
      data != oldWidget.data;
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  final LiveRepository _repository = LiveRepository.instance;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final AudioPlayer _giftAudioPlayer = AudioPlayer();

  LiveRoomDetailsData? _room;
  LiveRtcSessionData? _rtcSession;
  RtcEngine? _rtcEngine;
  Timer? _roomRefreshTimer;
  bool _isLoading = true;
  String? _errorMessage;
  String? _rtcErrorMessage;
  bool _rtcJoined = false;
  bool _isEndingLive = false;
  List<int> _remoteVideoUids = <int>[];
  String? _rtcEngineAppId;
  Set<int> _speakingVideoUids = <int>{};
  bool _localSpeaking = false;
  bool _isMuted = false;
  bool _showRoomTools = false;
  bool _showEffectControls = false;
  bool _showEffectSettingsPanel = false;
  bool _showViewersPanel = false;
  bool _showContributionPanel = false;
  bool _showPkPanel = false;
  bool _showPkLiveSettingsPanel = false;
  bool _beautyEnabled = false;
  int _pendingPkTapRequests = 0;
  LiveGiftEventData? _activeGiftEffect;
  Timer? _giftEffectTimer;
  int _lastSeenGiftEventId = 0;
  List<LiveActionSectionData> _actionSections = LiveActionSectionData.defaults;
  final Set<String> _preloadedGiftVisualPaths = <String>{};
  String? _preparedGiftSoundPath;
  String _pkTalkPermission = 'عند الطلب';
  String _pkPartyInvitePermission = 'عند الطلب';
  String _pkVoiceRoomInvitePermission = 'عند الطلب';
  String _pkChatPermission = 'عند الطلب';
  String _pkBattleDuration = '30د';

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void dispose() {
    _roomRefreshTimer?.cancel();
    _giftEffectTimer?.cancel();
    unawaited(_leaveLiveRtc());
    unawaited(_giftAudioPlayer.dispose());
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRoom() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final room = await _repository.getRoom(roomId: widget.args.roomId);
      if (!mounted) {
        return;
      }

      if (room.status != 'active') {
        setState(() {
          _errorMessage = 'انتهى اللايف';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _room = room;
        _lastSeenGiftEventId = _latestGiftEventId(room);
        _pkTalkPermission = room.pkSettings.talkPermission;
        _pkPartyInvitePermission = room.pkSettings.partyInvitePermission;
        _pkVoiceRoomInvitePermission =
            room.pkSettings.voiceRoomInvitePermission;
        _pkChatPermission = room.pkSettings.chatPermission;
        _pkBattleDuration = room.pkSettings.battleDuration;
        _isLoading = false;
      });
      _warmRecentGiftMedia(room);
      _startRoomRefreshTimer();
      unawaited(_loadLiveActionSections());
      unawaited(_joinLiveRtc(room));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLiveActionSections() async {
    try {
      final sections = await _repository.listActionSections();
      if (!mounted) {
        return;
      }

      setState(() {
        _actionSections = sections.isEmpty
            ? LiveActionSectionData.defaults
            : sections;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _actionSections = LiveActionSectionData.defaults;
      });
    }
  }

  Future<void> _joinLiveRtc(LiveRoomDetailsData room) async {
    try {
      final session = await _repository.joinRtc(roomId: room.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _rtcSession = session;
        _rtcErrorMessage = null;
      });
      unawaited(_refreshRoomSilently());

      if (!session.enabled || !session.configured || session.appId.isEmpty) {
        return;
      }

      final permissionsGranted = await _ensureLiveRtcPermissions(session);
      if (!permissionsGranted) {
        if (mounted) {
          setState(() {
            _rtcErrorMessage = 'يجب السماح بالكاميرا والميكروفون لتشغيل البث.';
          });
        }
        return;
      }

      await _ensureLiveRtcEngine(session.appId);
      final engine = _rtcEngine;
      if (engine == null) {
        return;
      }

      await engine.joinChannelWithUserAccount(
        token: session.token,
        channelId: session.channelName,
        userAccount: session.userAccount,
        options: _liveRtcOptions(session),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _rtcErrorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _ensureLiveRtcEngine(String appId) async {
    if (_rtcEngine != null && _rtcEngineAppId == appId) {
      return;
    }

    if (_rtcEngine != null) {
      try {
        await _rtcEngine!.leaveChannel();
        await _rtcEngine!.release();
      } catch (_) {}
      _rtcEngine = null;
      _rtcJoined = false;
      _remoteVideoUids = <int>[];
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    await engine.enableVideo();
    await engine.enableAudio();
    await engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 540, height: 960),
        frameRate: 15,
        bitrate: 900,
        orientationMode: OrientationMode.orientationModeAdaptive,
      ),
    );

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (!mounted) {
            return;
          }
          setState(() {
            _rtcJoined = true;
            _rtcErrorMessage = null;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!mounted) {
            return;
          }
          setState(() {
            _remoteVideoUids = <int>{..._remoteVideoUids, remoteUid}.toList();
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted || !_remoteVideoUids.contains(remoteUid)) {
            return;
          }
          setState(() {
            _remoteVideoUids = _remoteVideoUids
                .where((uid) => uid != remoteUid)
                .toList();
            _speakingVideoUids = {
              ..._speakingVideoUids.where((uid) => uid != remoteUid),
            };
          });
        },
        onAudioVolumeIndication:
            (connection, speakers, speakerNumber, totalVolume) {
              final nextSpeakingUids = <int>{};
              var nextLocalSpeaking = false;

              for (final speaker in speakers) {
                final volume = speaker.volume ?? 0;
                if (volume < 12) {
                  continue;
                }

                final uid = speaker.uid ?? 0;
                if (uid == 0) {
                  nextLocalSpeaking = true;
                } else {
                  nextSpeakingUids.add(uid);
                }
              }

              if (!mounted ||
                  (_localSpeaking == nextLocalSpeaking &&
                      _sameUidSet(_speakingVideoUids, nextSpeakingUids))) {
                return;
              }

              setState(() {
                _localSpeaking = nextLocalSpeaking;
                _speakingVideoUids = nextSpeakingUids;
              });
            },
        onTokenPrivilegeWillExpire: (connection, token) async {
          await _renewLiveRtcToken();
        },
        onRequestToken: (connection) async {
          await _renewLiveRtcToken();
        },
        onError: (err, message) {
          if (!mounted) {
            return;
          }
          setState(() {
            _rtcErrorMessage = message.isEmpty ? err.name : message;
          });
        },
      ),
    );
    await engine.enableAudioVolumeIndication(
      interval: 250,
      smooth: 3,
      reportVad: true,
    );

    _rtcEngine = engine;
    _rtcEngineAppId = appId;
  }

  bool _sameUidSet(Set<int> first, Set<int> second) {
    return first.length == second.length && first.every(second.contains);
  }

  Future<void> _renewLiveRtcToken() async {
    final room = _room;
    final engine = _rtcEngine;
    if (room == null || engine == null) {
      return;
    }

    try {
      final session = await _repository.renewRtcToken(roomId: room.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _rtcSession = session;
      });
      if (session.token.isNotEmpty) {
        await engine.renewToken(session.token);
      }
    } catch (_) {}
  }

  Future<void> _leaveLiveRtc() async {
    final roomId = _room?.id;
    final engine = _rtcEngine;
    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
      } catch (_) {}
    }
    if (roomId != null) {
      try {
        await _repository.leaveRtc(roomId: roomId);
      } catch (_) {}
    }
    _rtcEngine = null;
    _rtcJoined = false;
    _remoteVideoUids = <int>[];
    _speakingVideoUids = <int>{};
    _localSpeaking = false;
  }

  void _startRoomRefreshTimer() {
    _roomRefreshTimer?.cancel();
    _roomRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_refreshRoomSilently());
    });
  }

  Future<void> _refreshRoomSilently() async {
    final room = _room;
    if (room == null || _isLoading) {
      return;
    }

    try {
      if (_rtcSession != null) {
        try {
          await _repository.heartbeatRtc(roomId: room.id);
        } catch (_) {}
      }

      final updated = await _repository.getRoom(roomId: room.id);
      if (!mounted) {
        return;
      }

      if (updated.status != 'active') {
        _roomRefreshTimer?.cancel();
        await _leaveLiveRtc();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إنهاء اللايف')));
        Navigator.of(context).maybePop();
        return;
      }

      setState(() {
        _room = updated;
        _pkTalkPermission = updated.pkSettings.talkPermission;
        _pkPartyInvitePermission = updated.pkSettings.partyInvitePermission;
        _pkVoiceRoomInvitePermission =
            updated.pkSettings.voiceRoomInvitePermission;
        _pkChatPermission = updated.pkSettings.chatPermission;
        _pkBattleDuration = updated.pkSettings.battleDuration;
      });
      _warmRecentGiftMedia(updated);
      _showIncomingGiftEffectIfNeeded(updated);
    } catch (_) {}
  }

  Future<bool> _ensureLiveRtcPermissions(LiveRtcSessionData session) async {
    if (!session.isBroadcaster) {
      return true;
    }

    final camera = await Permission.camera.request();
    final microphone = await Permission.microphone.request();
    return camera.isGranted && microphone.isGranted;
  }

  ChannelMediaOptions _liveRtcOptions(LiveRtcSessionData session) {
    return ChannelMediaOptions(
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      clientRoleType: session.isBroadcaster
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
      autoSubscribeAudio: true,
      autoSubscribeVideo: true,
      publishCameraTrack: session.isBroadcaster,
      publishMicrophoneTrack: session.isBroadcaster,
      enableAudioRecordingOrPlayout: true,
      token: session.usesTokens ? session.token : null,
    );
  }

  Future<void> _applyPkSettings({
    String? talkPermission,
    String? partyInvitePermission,
    String? voiceRoomInvitePermission,
    String? chatPermission,
    String? battleDuration,
  }) async {
    if (_room == null) {
      return;
    }

    final nextSettings = LivePkSettingsData(
      talkPermission: talkPermission ?? _pkTalkPermission,
      partyInvitePermission: partyInvitePermission ?? _pkPartyInvitePermission,
      voiceRoomInvitePermission:
          voiceRoomInvitePermission ?? _pkVoiceRoomInvitePermission,
      chatPermission: chatPermission ?? _pkChatPermission,
      battleDuration: battleDuration ?? _pkBattleDuration,
    );

    setState(() {
      _pkTalkPermission = nextSettings.talkPermission;
      _pkPartyInvitePermission = nextSettings.partyInvitePermission;
      _pkVoiceRoomInvitePermission = nextSettings.voiceRoomInvitePermission;
      _pkChatPermission = nextSettings.chatPermission;
      _pkBattleDuration = nextSettings.battleDuration;
      _room = _room!.copyWith(pkSettings: nextSettings);
    });

    try {
      final updated = await _repository.updatePkSettings(
        roomId: widget.args.roomId,
        settings: nextSettings,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _room = updated;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر حفظ إعدادات PK الآن')));
    }
  }

  Future<void> _submitComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty || _room == null) {
      return;
    }

    try {
      final updated = await _repository.sendComment(
        roomId: widget.args.roomId,
        messageText: message,
      );
      if (!mounted) {
        return;
      }
      _commentController.clear();
      setState(() {
        _room = updated;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _openNotificationsSheet({bool roomOnly = true}) async {
    final notifications = await _repository.listNotifications(
      roomId: roomOnly ? widget.args.roomId : null,
    );
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _LiveRoomNotificationsSheet(notifications: notifications),
    );
  }

  Future<void> _openGiftSheet() async {
    if (_rtcSession?.role == 'host') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك إرسال هدية لنفسك')),
      );
      return;
    }

    final result = await showModalBottomSheet<LiveGiftSendResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LiveRoomGiftSheet(
        repository: _repository,
        roomId: widget.args.roomId,
        onGiftFocused: _warmGiftMedia,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _room = result.room;
    });
    _warmRecentGiftMedia(result.room);
    _showIncomingGiftEffectIfNeeded(result.room, forceLatest: true);
  }

  int _latestGiftEventId(LiveRoomDetailsData room) {
    var latest = 0;
    for (final event in room.recentGifts) {
      if (event.id > latest) {
        latest = event.id;
      }
    }
    return latest;
  }

  void _showIncomingGiftEffectIfNeeded(
    LiveRoomDetailsData room, {
    bool forceLatest = false,
  }) {
    if (room.recentGifts.isEmpty) {
      return;
    }

    final latest = room.recentGifts.reduce(
      (value, element) => element.id > value.id ? element : value,
    );

    if (!forceLatest && latest.id <= _lastSeenGiftEventId) {
      return;
    }

    _lastSeenGiftEventId = latest.id;
    _showGiftEffect(latest);
  }

  void _showGiftEffect(LiveGiftEventData event) {
    _giftEffectTimer?.cancel();
    _warmGiftMedia(event.gift);
    setState(() {
      _activeGiftEffect = event;
    });
    unawaited(_playGiftSound(event.gift.soundPath));

    final duration = Duration(
      milliseconds: event.gift.effectDurationMs.clamp(600, 8000).toInt(),
    );
    _giftEffectTimer = Timer(duration, () {
      if (!mounted || _activeGiftEffect?.id != event.id) {
        return;
      }
      setState(() {
        _activeGiftEffect = null;
      });
    });
  }

  Future<void> _playGiftSound(String soundPath) async {
    final path = soundPath.trim();
    if (path.isEmpty) {
      return;
    }

    try {
      if (_preparedGiftSoundPath == path) {
        await _giftAudioPlayer.seek(Duration.zero);
        await _giftAudioPlayer.resume();
        return;
      }

      await _giftAudioPlayer.stop();
      if (path.startsWith('assets/')) {
        final assetPath = path.replaceFirst(RegExp(r'^assets/'), '');
        await _giftAudioPlayer.play(AssetSource(assetPath));
      } else {
        await _giftAudioPlayer.play(UrlSource(resolveMediaUrl(path)));
      }
      _preparedGiftSoundPath = path;
    } catch (_) {}
  }

  void _warmRecentGiftMedia(LiveRoomDetailsData room) {
    for (final event in room.recentGifts) {
      _warmGiftMedia(event.gift, prepareSound: false);
    }
  }

  void _warmGiftMedia(LiveGiftItemData gift, {bool prepareSound = true}) {
    _precacheGiftVisual(gift.assetPath);
    _precacheGiftVisual(gift.effectAssetPath);

    if (prepareSound) {
      unawaited(_prepareGiftSound(gift.soundPath));
    }
  }

  void _precacheGiftVisual(String path) {
    final resolvedPath = path.trim();
    if (resolvedPath.isEmpty || !_preloadedGiftVisualPaths.add(resolvedPath)) {
      return;
    }

    unawaited(precacheResolvedImage(context, resolvedPath));
  }

  Future<void> _prepareGiftSound(String soundPath) async {
    final path = soundPath.trim();
    if (path.isEmpty || _preparedGiftSoundPath == path) {
      return;
    }

    try {
      if (path.startsWith('assets/')) {
        final assetPath = path.replaceFirst(RegExp(r'^assets/'), '');
        await _giftAudioPlayer.setSource(AssetSource(assetPath));
      } else {
        await _giftAudioPlayer.setSource(UrlSource(resolveMediaUrl(path)));
      }
      _preparedGiftSoundPath = path;
    } catch (_) {}
  }

  Future<void> _openReportSheet() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LiveRoomReportSheet(),
    );
    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    try {
      await _repository.reportRoom(roomId: widget.args.roomId, reason: reason);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _toggleLiveMute({LiveActionButtonData? action}) async {
    final nextMuted = !_isMuted;

    setState(() {
      _isMuted = nextMuted;
    });

    try {
      final engine = _rtcEngine;
      if (engine != null) {
        if (_rtcSession?.isBroadcaster == true) {
          await engine.muteLocalAudioStream(nextMuted);
        } else {
          await engine.muteAllRemoteAudioStreams(nextMuted);
        }
      }

      if (action != null && _room != null) {
        await _repository.triggerAction(roomId: _room!.id, action: action);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nextMuted ? 'تم كتم الصوت' : 'تم تشغيل الصوت')),
    );
  }

  Future<void> _handleLiveManagementAction(LiveActionButtonData action) async {
    final room = _room;
    if (room == null) {
      return;
    }

    Future<LiveActionResultData?> recordAction() async {
      try {
        return await _repository.triggerAction(roomId: room.id, action: action);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
        return null;
      }
    }

    switch (action.behavior) {
      case 'mute':
        _setEffectSettingsPanelVisible(false);
        await _toggleLiveMute(action: action);
        return;
      case 'beauty':
        final nextEnabled = !_beautyEnabled;
        setState(() {
          _beautyEnabled = nextEnabled;
        });
        try {
          await _rtcEngine?.setBeautyEffectOptions(
            enabled: nextEnabled,
            options: const BeautyOptions(
              lighteningContrastLevel:
                  LighteningContrastLevel.lighteningContrastNormal,
              lighteningLevel: 0.35,
              smoothnessLevel: 0.55,
              rednessLevel: 0.12,
              sharpnessLevel: 0.08,
            ),
          );
        } catch (_) {}
        final result = await recordAction();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextEnabled
                  ? 'تم تفعيل تحسينات الجمال'
                  : 'تم إيقاف تحسينات الجمال',
            ),
          ),
        );
        if (result != null) {
          _showLiveActionDetails(result.action, result.message);
        }
        return;
      case 'notifications':
        _setEffectSettingsPanelVisible(false);
        await recordAction();
        await _openNotificationsSheet();
        return;
      case 'viewers':
        _setEffectSettingsPanelVisible(false);
        await recordAction();
        _setViewersPanelVisible(true);
        return;
      case 'supporters':
      case 'entry_ranking':
        _setEffectSettingsPanelVisible(false);
        await recordAction();
        _setContributionPanelVisible(true);
        return;
      case 'gift':
        _setEffectSettingsPanelVisible(false);
        await recordAction();
        await _openGiftSheet();
        return;
      case 'pk':
        _setEffectSettingsPanelVisible(false);
        await recordAction();
        _setPkPanelVisible(true);
        return;
      case 'share':
        _setEffectSettingsPanelVisible(false);
        await recordAction();
        await _copyShareLink();
        return;
      case 'report':
        _setEffectSettingsPanelVisible(false);
        await recordAction();
        await _openReportSheet();
        return;
      default:
        final result = await recordAction();
        if (!mounted) {
          return;
        }
        _showLiveActionDetails(action, result?.message);
    }
  }

  void _showLiveActionDetails(LiveActionButtonData action, [String? message]) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LiveActionDetailsSheet(
        action: action,
        message: message ?? 'تم تنفيذ الأمر.',
      ),
    );
  }

  Future<void> _copyShareLink() async {
    if (_room == null) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text:
            'انضم إلى لايف ${_room!.title} - ${_room!.hostIdLabel} على Hallo Party',
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ رابط الدعوة')));
  }

  Future<void> _openPkInviteSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LivePkInviteSheet(
        repository: _repository,
        roomId: widget.args.roomId,
      ),
    );
    if (mounted) {
      setState(() {
        _showPkPanel = false;
        _showEffectControls = false;
      });
    }
    await _refreshRoomSilently();
  }

  Future<void> _startPkMatching() async {
    final room = _room;
    if (room == null) {
      return;
    }

    try {
      final updated = await _repository.startPkMatching(roomId: room.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _room = updated;
        _showPkPanel = false;
        _showEffectControls = false;
        _showPkLiveSettingsPanel = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم بدء انتظار PK')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _endPkBattle() async {
    final room = _room;
    if (room == null) {
      return;
    }

    try {
      final updated = await _repository.endPkBattle(roomId: room.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _room = updated;
        _showPkPanel = false;
        _showEffectControls = false;
        _showPkLiveSettingsPanel = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنهاء PK')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _endLiveRoom() async {
    final room = _room;
    if (room == null || _isEndingLive) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء اللايف؟'),
        content: const Text('سيتم إيقاف البث وإخفاؤه من قائمة اللايف.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: LiveRoomScreen._accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isEndingLive = true;
    });

    try {
      await _repository.endRoom(roomId: room.id);
      _roomRefreshTimer?.cancel();
      await _leaveLiveRtc();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isEndingLive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _handleCloseLiveRoom() async {
    if (_isEndingLive) {
      return;
    }

    if (_rtcSession?.role == 'host') {
      await _endLiveRoom();
      return;
    }

    await _leaveLiveRtc();
    if (!mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _sendPkTap(String side) async {
    final room = _room;
    if (room == null || !room.pkState.isActive) {
      return;
    }

    setState(() {
      _pendingPkTapRequests += 1;
      _room = room.copyWith(
        pkState: room.pkState.copyWith(
          hostTapCount: side == 'host'
              ? room.pkState.hostTapCount + 1
              : room.pkState.hostTapCount,
          guestTapCount: side == 'guest'
              ? room.pkState.guestTapCount + 1
              : room.pkState.guestTapCount,
          hostScore: side == 'host'
              ? room.pkState.hostScore + 1
              : room.pkState.hostScore,
          guestScore: side == 'guest'
              ? room.pkState.guestScore + 1
              : room.pkState.guestScore,
        ),
      );
    });

    try {
      final updated = await _repository.sendPkTap(roomId: room.id, side: side);
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingPkTapRequests = math.max(0, _pendingPkTapRequests - 1);
        if (_pendingPkTapRequests == 0) {
          _room = updated;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingPkTapRequests = math.max(0, _pendingPkTapRequests - 1);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _setRoomToolsVisible(bool value) {
    setState(() {
      _showRoomTools = value;
      if (value) {
        _showEffectSettingsPanel = false;
        _showViewersPanel = false;
        _showContributionPanel = false;
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setEffectControlsVisible(bool value) {
    setState(() {
      _showEffectControls = value;
      if (!value) {
        _showEffectSettingsPanel = false;
        _showViewersPanel = false;
        _showContributionPanel = false;
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setEffectSettingsPanelVisible(bool value) {
    setState(() {
      _showEffectSettingsPanel = value;
      if (value) {
        _showEffectControls = true;
        _showViewersPanel = false;
        _showContributionPanel = false;
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setViewersPanelVisible(bool value) {
    setState(() {
      _showViewersPanel = value;
      if (value) {
        _showEffectSettingsPanel = false;
        _showContributionPanel = false;
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setContributionPanelVisible(
    bool value, {
    bool returnToViewers = false,
  }) {
    setState(() {
      _showContributionPanel = value;
      _showViewersPanel = returnToViewers;
      if (value) {
        _showPkPanel = false;
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setPkPanelVisible(bool value) {
    setState(() {
      _showPkPanel = value;
      if (value) {
        _showEffectControls = true;
        _showEffectSettingsPanel = false;
        _showViewersPanel = false;
        _showContributionPanel = false;
        _showPkLiveSettingsPanel = false;
      }
      if (!value) {
        _showPkLiveSettingsPanel = false;
      }
    });
  }

  void _setPkLiveSettingsPanelVisible(bool value) {
    setState(() {
      _showPkLiveSettingsPanel = value;
      if (value) {
        _showEffectControls = true;
        _showPkPanel = false;
        _showEffectSettingsPanel = false;
        _showViewersPanel = false;
        _showContributionPanel = false;
      }
    });
  }

  void _openLiveUserProfile(_LiveRoomComment comment) {
    final userId = comment.userId;
    if (userId == null || userId < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد ملف شخصي مرتبط بهذا التعليق')),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileScreenArgs(
        userId: userId,
        fallbackName: comment.name,
        fallbackAvatarAsset: comment.avatarAsset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _room == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تعذر تحميل اللايف الآن',
                  style: TextStyle(
                    color: LiveRoomScreen._primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadRoom,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _LiveRoomDataScope(
      data: _room!,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _room!.backgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            if (_showEffectControls)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/live152_effect_overlay.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            Positioned.fill(
              child: SafeArea(
                top: false,
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final safePadding = MediaQuery.paddingOf(context);
                    final keyboardBottom = MediaQuery.viewInsetsOf(
                      context,
                    ).bottom;
                    final topPadding = math.max(
                      safePadding.top + 8,
                      constraints.maxHeight >= 760 ? 34.0 : 18.0,
                    );
                    final bottomControlsOffset =
                        math.max(keyboardBottom, safePadding.bottom) + 10;
                    final commentsBottom = bottomControlsOffset + 58;
                    final commentsHeight = math.min(
                      height * 0.36,
                      math.max(174.0, height * 0.24),
                    );

                    final comments = _room!.comments
                        .map(
                          (comment) => _LiveRoomComment(
                            userId: comment.userId,
                            name: comment.name,
                            message: comment.message,
                            avatarAsset: comment.avatarAsset,
                          ),
                        )
                        .toList();

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: KeyedSubtree(
                            key: _showEffectControls
                                ? const ValueKey('live-room-effects-mode')
                                : null,
                            child: _LiveRoomVideoStage(
                              height: height,
                              isFullscreen: true,
                              rtcEngine: _rtcEngine,
                              rtcSession: _rtcSession,
                              rtcJoined: _rtcJoined,
                              remoteVideoUids: _remoteVideoUids,
                              speakingRemoteUids: _speakingVideoUids,
                              localSpeaking: _localSpeaking,
                              rtcErrorMessage: _rtcErrorMessage,
                              onPkTap: _sendPkTap,
                            ),
                          ),
                        ),
                        Positioned(
                          top: topPadding,
                          left: 10,
                          right: 10,
                          child: _LiveRoomHeader(
                            onClose: _handleCloseLiveRoom,
                            isCompact:
                                _showRoomTools ||
                                _showEffectControls ||
                                _showEffectSettingsPanel,
                          ),
                        ),
                        Positioned(
                          left: width * 0.22,
                          right: 10,
                          bottom: commentsBottom,
                          height: commentsHeight,
                          child: _LiveRoomChatPanel(
                            comments: comments,
                            onProfileTap: _openLiveUserProfile,
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: bottomControlsOffset,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _showEffectControls
                                ? _LiveRoomEffectsToolbar(
                                    onGiftTap: _openGiftSheet,
                                    onSettingsTap: () =>
                                        _setEffectSettingsPanelVisible(true),
                                    onPkTap: () => _setPkPanelVisible(true),
                                    onNotificationTap: () =>
                                        _openNotificationsSheet(),
                                    onGridTap: () => _setRoomToolsVisible(true),
                                    onPeopleTap: () =>
                                        _setViewersPanelVisible(true),
                                    onMessageTap: () {
                                      _setEffectControlsVisible(false);
                                      _commentFocusNode.requestFocus();
                                    },
                                  )
                                : _LiveRoomComposer(
                                    controller: _commentController,
                                    focusNode: _commentFocusNode,
                                    onGiftTap: _openGiftSheet,
                                    onPeopleTap: () =>
                                        _setViewersPanelVisible(true),
                                    onChatTap: () =>
                                        _commentFocusNode.requestFocus(),
                                    onRoomToolsTap: () =>
                                        _setRoomToolsVisible(true),
                                    onSendTap: _submitComment,
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_activeGiftEffect != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: _LiveGiftEffectOverlay(event: _activeGiftEffect!),
                ),
              ),
            if (_showRoomTools) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _setRoomToolsVisible(false),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                    child: Container(color: const Color(0x33424242)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _LiveRoomToolsSheet(
                  onDismiss: () => _setRoomToolsVisible(false),
                  isMuted: _isMuted,
                  canEndLive: _rtcSession?.isBroadcaster == true,
                  isEndingLive: _isEndingLive,
                  onMuteTap: () {
                    _setRoomToolsVisible(false);
                    _toggleLiveMute();
                  },
                  onReportTap: () {
                    _setRoomToolsVisible(false);
                    _openReportSheet();
                  },
                  onShareTap: () {
                    _setRoomToolsVisible(false);
                    _copyShareLink();
                  },
                  onEffectsTap: () {
                    _setRoomToolsVisible(false);
                    _setEffectSettingsPanelVisible(true);
                  },
                  onEndLiveTap: () {
                    _setRoomToolsVisible(false);
                    _endLiveRoom();
                  },
                ),
              ),
            ],
            if (_showEffectSettingsPanel) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setEffectSettingsPanelVisible(false),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _LiveRoomEffectSettingsPanel(
                  onDismiss: () => _setEffectSettingsPanelVisible(false),
                  sections: _actionSections,
                  isHost: _rtcSession?.isBroadcaster == true,
                  onActionTap: _handleLiveManagementAction,
                ),
              ),
            ],
            if (_showViewersPanel) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setViewersPanelVisible(false),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                    child: Container(color: const Color(0x33424242)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _LiveRoomViewersPanel(
                  onDismiss: () => _setViewersPanelVisible(false),
                  onTopSupportersTap: () => _setContributionPanelVisible(
                    true,
                    returnToViewers: false,
                  ),
                ),
              ),
            ],
            if (_showContributionPanel) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setContributionPanelVisible(
                    false,
                    returnToViewers: true,
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                    child: Container(color: const Color(0x33424242)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _LiveRoomContributionPanel(
                  onDismiss: () => _setContributionPanelVisible(
                    false,
                    returnToViewers: true,
                  ),
                ),
              ),
            ],
            if (_showPkPanel) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setPkPanelVisible(false),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                    child: Container(color: const Color(0x33424242)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _LiveRoomPkPanel(
                  onDismiss: () => _setPkPanelVisible(false),
                  isPkVisible: _room!.pkState.isPkVisible,
                  onStartMatchingTap: _startPkMatching,
                  onEndPkTap: _endPkBattle,
                  onSettingsTap: () => _setPkLiveSettingsPanelVisible(true),
                  onChallengeFriendsTap: _openPkInviteSheet,
                ),
              ),
            ],
            if (_showPkLiveSettingsPanel) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setPkLiveSettingsPanelVisible(false),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
                    child: Container(color: const Color(0x33424242)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _LiveRoomPkLiveSettingsPanel(
                  onDismiss: () => _setPkLiveSettingsPanelVisible(false),
                  talkPermission: _pkTalkPermission,
                  onTalkPermissionChanged: (value) =>
                      _applyPkSettings(talkPermission: value),
                  partyInvitePermission: _pkPartyInvitePermission,
                  onPartyInvitePermissionChanged: (value) =>
                      _applyPkSettings(partyInvitePermission: value),
                  voiceRoomInvitePermission: _pkVoiceRoomInvitePermission,
                  onVoiceRoomInvitePermissionChanged: (value) =>
                      _applyPkSettings(voiceRoomInvitePermission: value),
                  chatPermission: _pkChatPermission,
                  onChatPermissionChanged: (value) =>
                      _applyPkSettings(chatPermission: value),
                  battleDuration: _pkBattleDuration,
                  onBattleDurationChanged: (value) =>
                      _applyPkSettings(battleDuration: value),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveRoomHeader extends StatelessWidget {
  const _LiveRoomHeader({required this.onClose, this.isCompact = false});

  final VoidCallback onClose;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final room = _LiveRoomDataScope.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactWidth = constraints.maxWidth < 360 || isCompact;
        final closeSize = compactWidth ? 38.0 : 44.0;
        final chipWidth = compactWidth ? 56.0 : 66.0;
        final chipHeight = compactWidth ? 24.0 : 28.0;

        return Row(
          children: [
            GestureDetector(
              key: const ValueKey('live-room-close'),
              onTap: onClose,
              child: Container(
                width: closeSize,
                height: closeSize,
                decoration: const BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/live150_power.png',
                    width: closeSize * 0.56,
                    height: closeSize * 0.56,
                  ),
                ),
              ),
            ),
            SizedBox(width: compactWidth ? 6 : 8),
            _LiveRoomCounterChip(
              icon: Icons.people_alt_rounded,
              value: '${room.viewerCount}',
              width: chipWidth,
              height: chipHeight,
              compact: compactWidth,
            ),
            SizedBox(width: compactWidth ? 5 : 7),
            _LiveRoomCounterChip(
              assetIcon: 'assets/images/live150_coin.png',
              value: '${room.coinCount}',
              width: chipWidth,
              height: chipHeight,
              compact: compactWidth,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _LiveRoomHostBadge(isCompact: compactWidth),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveRoomCounterChip extends StatelessWidget {
  const _LiveRoomCounterChip({
    required this.value,
    required this.width,
    required this.height,
    required this.compact,
    this.icon,
    this.assetIcon,
  });

  final String value;
  final double width;
  final double height;
  final bool compact;
  final IconData? icon;
  final String? assetIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
      decoration: BoxDecoration(
        color: const Color(0x8A000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetIcon != null)
              Image.asset(
                assetIcon!,
                width: compact ? 12 : 14,
                height: compact ? 12 : 14,
              )
            else
              Icon(icon, color: Colors.white, size: compact ? 12 : 15),
            SizedBox(width: compact ? 4 : 5),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomHostBadge extends StatefulWidget {
  const _LiveRoomHostBadge({this.isCompact = false});

  final bool isCompact;

  @override
  State<_LiveRoomHostBadge> createState() => _LiveRoomHostBadgeState();
}

class _LiveRoomHostBadgeState extends State<_LiveRoomHostBadge> {
  bool _isTogglingFollow = false;

  Future<void> _toggleHostFollow(LiveRoomDetailsData room) async {
    final hostUserId = room.hostUserId;
    if (hostUserId == null || _isTogglingFollow) {
      return;
    }

    setState(() {
      _isTogglingFollow = true;
    });

    try {
      final result = await SocialRepository.instance.toggleFollow(
        userId: hostUserId,
      );
      if (!mounted) {
        return;
      }
      final relation = result.user.relationship;
      final message = relation.isFriend
          ? 'أصبحتم أصدقاء'
          : relation.isFollowing
          ? 'تمت المتابعة'
          : 'تم إلغاء المتابعة';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFollow = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _LiveRoomDataScope.of(context);
    final avatarSize = widget.isCompact ? 42.0 : 54.0;
    final badgeSize = widget.isCompact ? 16.0 : 20.0;
    final titleSize = widget.isCompact ? 11.0 : 13.0;
    final hostSize = widget.isCompact ? 9.5 : 11.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxWidth: widget.isCompact ? 168 : 210),
        padding: EdgeInsetsDirectional.only(
          start: widget.isCompact ? 6 : 8,
          end: widget.isCompact ? 6 : 8,
          top: widget.isCompact ? 5 : 6,
          bottom: widget.isCompact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0x94000000),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x30FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB0D7F5), Color(0xFF285F98)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ResolvedImage(
                    path: room.hostAvatarAsset,
                    fit: BoxFit.cover,
                    width: avatarSize,
                    height: avatarSize,
                  ),
                ),
                Positioned(
                  left: -2,
                  top: -3,
                  child: InkWell(
                    onTap: () => _toggleHostFollow(room),
                    borderRadius: BorderRadius.circular(badgeSize / 2),
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: const BoxDecoration(
                        color: LiveRoomScreen._primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: _isTogglingFollow
                          ? SizedBox(
                              width: badgeSize * 0.48,
                              height: badgeSize * 0.48,
                              child: const CircularProgressIndicator(
                                strokeWidth: 1.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              '+',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.isCompact ? 10 : 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.title,
                    key: const ValueKey('live-room-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.hostName.trim().isEmpty
                        ? room.hostIdLabel
                        : room.hostName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: hostSize,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  if (!widget.isCompact) ...[
                    const SizedBox(height: 2),
                    Text(
                      room.hostIdLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomVideoStage extends StatelessWidget {
  const _LiveRoomVideoStage({
    required this.height,
    required this.isFullscreen,
    required this.rtcEngine,
    required this.rtcSession,
    required this.rtcJoined,
    required this.remoteVideoUids,
    required this.speakingRemoteUids,
    required this.localSpeaking,
    required this.rtcErrorMessage,
    required this.onPkTap,
  });

  final double height;
  final bool isFullscreen;
  final RtcEngine? rtcEngine;
  final LiveRtcSessionData? rtcSession;
  final bool rtcJoined;
  final List<int> remoteVideoUids;
  final Set<int> speakingRemoteUids;
  final bool localSpeaking;
  final String? rtcErrorMessage;
  final ValueChanged<String> onPkTap;

  @override
  Widget build(BuildContext context) {
    final room = _LiveRoomDataScope.of(context);
    final session = rtcSession;
    final canRenderRtc =
        rtcEngine != null &&
        session != null &&
        session.enabled &&
        session.configured &&
        rtcJoined;
    final isBroadcaster = session?.isBroadcaster == true;

    final isPkVisible = room.pkState.isPkVisible;
    final primaryRemoteUid = remoteVideoUids.isEmpty
        ? null
        : remoteVideoUids.first;
    final secondaryRemoteUid = remoteVideoUids.length < 2
        ? null
        : remoteVideoUids[1];
    final screenWidth = MediaQuery.sizeOf(context).width;
    final safePadding = MediaQuery.paddingOf(context);
    const pkHorizontalMargin = 14.0;
    const pkGap = 8.0;
    final pkPaneSize = ((screenWidth - (pkHorizontalMargin * 2) - pkGap) / 2)
        .clamp(136.0, 220.0)
        .toDouble();
    final pkTotalWidth = (pkPaneSize * 2) + pkGap;
    final pkScoreTop = isFullscreen
        ? math.max(safePadding.top + 86, 104.0)
        : 36.0;
    final pkTop = isFullscreen ? pkScoreTop + 96 : 0.0;
    final pkTimerTop = isFullscreen
        ? math.max(safePadding.top + 58, 72.0)
        : 15.0;
    final pkPaneTotalHeight = pkPaneSize + 34;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          if (isPkVisible)
            Positioned(
              top: pkTop,
              left: 0,
              right: 0,
              height: pkPaneTotalHeight,
              child: Center(
                child: SizedBox(
                  width: pkTotalWidth,
                  child: Row(
                    children: [
                      _LiveRoomVideoPane(
                        imageAsset: room.leftVideoAsset,
                        barColor: LiveRoomScreen._primaryBlue,
                        alignment: Alignment.topLeft,
                        showTopBar: true,
                        boxed: true,
                        participantName: room.hostName,
                        rtcEngine: rtcEngine,
                        rtcSession: session,
                        remoteVideoUid: primaryRemoteUid,
                        isSpeaking: isBroadcaster
                            ? localSpeaking
                            : primaryRemoteUid != null &&
                                  speakingRemoteUids.contains(primaryRemoteUid),
                        renderMode: canRenderRtc
                            ? (isBroadcaster
                                  ? _LiveRoomVideoRenderMode.local
                                  : _LiveRoomVideoRenderMode.remote)
                            : _LiveRoomVideoRenderMode.fallback,
                      ),
                      const SizedBox(width: pkGap),
                      _LiveRoomVideoPane(
                        imageAsset: room.rightVideoAsset,
                        barColor: LiveRoomScreen._accentRed,
                        alignment: Alignment.topRight,
                        showTopBar: true,
                        boxed: true,
                        participantName: room.pkState.guestName.trim().isEmpty
                            ? 'خصم PK'
                            : room.pkState.guestName,
                        rtcEngine: rtcEngine,
                        rtcSession: session,
                        remoteVideoUid: isBroadcaster
                            ? primaryRemoteUid
                            : secondaryRemoteUid,
                        isSpeaking:
                            canRenderRtc &&
                            ((isBroadcaster &&
                                    primaryRemoteUid != null &&
                                    speakingRemoteUids.contains(
                                      primaryRemoteUid,
                                    )) ||
                                (!isBroadcaster &&
                                    secondaryRemoteUid != null &&
                                    speakingRemoteUids.contains(
                                      secondaryRemoteUid,
                                    ))),
                        renderMode:
                            canRenderRtc &&
                                (isBroadcaster
                                    ? primaryRemoteUid != null
                                    : secondaryRemoteUid != null)
                            ? _LiveRoomVideoRenderMode.remote
                            : _LiveRoomVideoRenderMode.fallback,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isFullscreen ? 0 : 6),
                child: Row(
                  children: [
                    _LiveRoomVideoPane(
                      imageAsset: room.leftVideoAsset,
                      barColor: LiveRoomScreen._primaryBlue,
                      alignment: Alignment.topRight,
                      showTopBar: !isFullscreen,
                      boxed: false,
                      participantName: room.hostName,
                      rtcEngine: rtcEngine,
                      rtcSession: session,
                      remoteVideoUid: primaryRemoteUid,
                      isSpeaking: isBroadcaster
                          ? localSpeaking
                          : primaryRemoteUid != null &&
                                speakingRemoteUids.contains(primaryRemoteUid),
                      renderMode: canRenderRtc
                          ? (isBroadcaster
                                ? _LiveRoomVideoRenderMode.local
                                : _LiveRoomVideoRenderMode.remote)
                          : _LiveRoomVideoRenderMode.fallback,
                    ),
                  ],
                ),
              ),
            ),
          if (room.pkState.isActive)
            Positioned.fill(
              child: _LivePkTapOverlay(enabled: true, onTap: onPkTap),
            ),
          if (isPkVisible)
            Positioned(
              top: pkTimerTop,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 88,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0x9E000000),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        color: Colors.white,
                        size: 6,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        room.pkState.isMatching
                            ? 'انتظار PK'
                            : room.battleTimerLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isPkVisible)
            Positioned(
              top: pkScoreTop,
              left: 14,
              right: 14,
              child: _LivePkScoreBar(
                hostScore: room.pkState.hostScore,
                guestScore: room.pkState.guestScore,
                secondsRemaining: room.pkState.secondsRemaining,
                winnerSide: room.pkState.winnerSide,
                isMatching: room.pkState.isMatching,
              ),
            ),
          if (rtcErrorMessage != null && rtcErrorMessage!.trim().isNotEmpty)
            Positioned(
              left: 14,
              right: 14,
              top: 34,
              child: _LiveRoomVideoStatusPill(text: rtcErrorMessage!),
            )
          else if (session != null && (!session.enabled || !session.configured))
            Positioned(
              left: 14,
              right: 14,
              top: 34,
              child: _LiveRoomVideoStatusPill(
                text: !session.enabled
                    ? 'تم إيقاف فيديو اللايف من الإدارة'
                    : 'إعدادات Agora للفيديو غير مكتملة',
              ),
            ),
        ],
      ),
    );
  }
}

enum _LiveRoomVideoRenderMode { fallback, local, remote }

class _LiveRoomVideoPane extends StatelessWidget {
  const _LiveRoomVideoPane({
    required this.imageAsset,
    required this.barColor,
    required this.alignment,
    required this.showTopBar,
    required this.boxed,
    required this.participantName,
    required this.rtcEngine,
    required this.rtcSession,
    required this.remoteVideoUid,
    required this.renderMode,
    required this.isSpeaking,
  });

  final String imageAsset;
  final Color barColor;
  final Alignment alignment;
  final bool showTopBar;
  final bool boxed;
  final String participantName;
  final RtcEngine? rtcEngine;
  final LiveRtcSessionData? rtcSession;
  final int? remoteVideoUid;
  final _LiveRoomVideoRenderMode renderMode;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final video = _buildVideoView();
    final content = Stack(
      children: [
        Positioned.fill(child: video),
        if (isSpeaking)
          Positioned(
            left: alignment == Alignment.topLeft ? 8 : null,
            right: alignment == Alignment.topRight ? 8 : null,
            top: showTopBar ? 22 : 88,
            child: _LiveSpeakingIndicator(color: barColor),
          ),
        if (showTopBar && !boxed)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 20,
              color: barColor.withValues(alpha: 0.92),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Align(
                alignment: alignment,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person, color: Colors.white, size: 11),
                    SizedBox(width: 3),
                    Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (boxed) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _LivePkParticipantNamePill(
              name: participantName,
              color: barColor,
              alignment: alignment,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF05070D),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: barColor.withValues(alpha: 0.70),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: content,
              ),
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: Container(clipBehavior: Clip.none, child: content),
    );
  }

  Widget _buildVideoView() {
    final engine = rtcEngine;
    final session = rtcSession;

    if (engine != null &&
        session != null &&
        renderMode == _LiveRoomVideoRenderMode.local) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0),
          useAndroidSurfaceView: true,
        ),
      );
    }

    if (engine != null &&
        session != null &&
        renderMode == _LiveRoomVideoRenderMode.remote &&
        remoteVideoUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: remoteVideoUid),
          connection: RtcConnection(channelId: session.channelName),
          useAndroidSurfaceView: true,
        ),
      );
    }

    if (session != null && session.enabled && session.configured) {
      return _LiveRtcWaitingView(
        text:
            session.isBroadcaster &&
                renderMode == _LiveRoomVideoRenderMode.remote
            ? 'في انتظار ضيف PK'
            : 'في انتظار بدء البث الحقيقي',
      );
    }

    return Image.asset(
      imageAsset,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
  }
}

class _LiveSpeakingIndicator extends StatefulWidget {
  const _LiveSpeakingIndicator({required this.color});

  final Color color;

  @override
  State<_LiveSpeakingIndicator> createState() => _LiveSpeakingIndicatorState();
}

class _LiveSpeakingIndicatorState extends State<_LiveSpeakingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.76),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final phase = (_controller.value + (index * 0.22)) % 1.0;
                final height = 5.0 + (math.sin(phase * math.pi) * 9.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.2),
                  child: Container(
                    width: 3,
                    height: height,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _LiveRtcWaitingView extends StatelessWidget {
  const _LiveRtcWaitingView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0x33285F98),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePkParticipantNamePill extends StatelessWidget {
  const _LivePkParticipantNamePill({
    required this.name,
    required this.color,
    required this.alignment,
  });

  final String name;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 28,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: const Color(0xD9000000),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.65)),
        ),
        child: Align(
          alignment: alignment == Alignment.topLeft
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Text(
            name.trim().isEmpty ? 'ضيف PK' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveRoomVideoStatusPill extends StatelessWidget {
  const _LiveRoomVideoStatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC000000),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePkMomentumIndicator extends StatefulWidget {
  const _LivePkMomentumIndicator({
    required this.hostScore,
    required this.guestScore,
    required this.winnerSide,
  });

  @override
  State<_LivePkMomentumIndicator> createState() =>
      _LivePkMomentumIndicatorState();

  final int hostScore;
  final int guestScore;
  final String winnerSide;
}

class _LivePkMomentumIndicatorState extends State<_LivePkMomentumIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explicitWinner =
        widget.winnerSide == 'host' || widget.winnerSide == 'guest'
        ? widget.winnerSide
        : '';
    final leadingSide = explicitWinner.isNotEmpty
        ? explicitWinner
        : widget.hostScore == widget.guestScore
        ? ''
        : (widget.hostScore > widget.guestScore ? 'host' : 'guest');
    final losingSide = leadingSide == 'host'
        ? 'guest'
        : leadingSide == 'guest'
        ? 'host'
        : '';
    final pointsGap = (widget.hostScore - widget.guestScore).abs();
    final color = leadingSide == 'guest'
        ? LiveRoomScreen._accentRed
        : leadingSide == 'host'
        ? LiveRoomScreen._primaryBlue
        : const Color(0xFFFFD15C);
    final icon = losingSide == 'guest'
        ? Icons.keyboard_double_arrow_right_rounded
        : losingSide == 'host'
        ? Icons.keyboard_double_arrow_left_rounded
        : Icons.compare_arrows_rounded;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final direction = losingSide == 'guest'
            ? 1.0
            : losingSide == 'host'
            ? -1.0
            : 0.0;
        return Transform.translate(
          offset: Offset(direction * (3 + (value * 10)), 0),
          child: Transform.scale(scale: 0.94 + (value * 0.12), child: child),
        );
      },
      child: Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xF00B101A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color, width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              leadingSide.isEmpty ? '⚔️' : '🏆',
              style: const TextStyle(fontSize: 15, height: 1),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: color, size: 17),
            if (pointsGap > 0) ...[
              const SizedBox(width: 4),
              Text(
                '+$pointsGap',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LivePkScoreBar extends StatelessWidget {
  const _LivePkScoreBar({
    required this.hostScore,
    required this.guestScore,
    required this.secondsRemaining,
    required this.winnerSide,
    required this.isMatching,
  });

  final int hostScore;
  final int guestScore;
  final int secondsRemaining;
  final String winnerSide;
  final bool isMatching;

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, hostScore + guestScore);
    final hostFlex = math.max(1, hostScore);
    final guestFlex = math.max(1, guestScore);
    final timeLabel = isMatching
        ? 'انتظار الخصم'
        : '${(secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(secondsRemaining % 60).toString().padLeft(2, '0')}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
        decoration: BoxDecoration(
          color: const Color(0xB3000000),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _LivePkScoreChip(
                  score: hostScore,
                  color: LiveRoomScreen._primaryBlue,
                  isWinner: winnerSide == 'host',
                ),
                Expanded(
                  child: _LivePkScoreCenter(
                    timeLabel: timeLabel,
                    hostScore: hostScore,
                    guestScore: guestScore,
                    winnerSide: winnerSide,
                  ),
                ),
                _LivePkScoreChip(
                  score: guestScore,
                  color: LiveRoomScreen._accentRed,
                  isWinner: winnerSide == 'guest',
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 9,
                child: Row(
                  children: [
                    Expanded(
                      flex: total == 1 ? 1 : hostFlex,
                      child: Container(color: LiveRoomScreen._primaryBlue),
                    ),
                    Expanded(
                      flex: total == 1 ? 1 : guestFlex,
                      child: Container(color: LiveRoomScreen._accentRed),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePkScoreCenter extends StatelessWidget {
  const _LivePkScoreCenter({
    required this.timeLabel,
    required this.hostScore,
    required this.guestScore,
    required this.winnerSide,
  });

  final String timeLabel;
  final int hostScore;
  final int guestScore;
  final String winnerSide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LivePkMomentumIndicator(
            hostScore: hostScore,
            guestScore: guestScore,
            winnerSide: winnerSide,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LiveRoomScreen._primaryBlue,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePkScoreChip extends StatelessWidget {
  const _LivePkScoreChip({
    required this.score,
    required this.color,
    required this.isWinner,
  });

  final int score;
  final Color color;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner) ...[
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD15C),
              size: 14,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePkTapOverlay extends StatefulWidget {
  const _LivePkTapOverlay({required this.enabled, required this.onTap});

  final bool enabled;
  final ValueChanged<String> onTap;

  @override
  State<_LivePkTapOverlay> createState() => _LivePkTapOverlayState();
}

class _LivePkTapOverlayState extends State<_LivePkTapOverlay> {
  static const int _maxActiveHearts = 96;
  static const int _heartsPerTap = 8;

  final List<_LivePkHeartBurstData> _bursts = <_LivePkHeartBurstData>[];
  final math.Random _random = math.Random();
  int _nextBurstId = 0;

  void _handleTapDown(TapDownDetails details, BoxConstraints constraints) {
    if (!widget.enabled) {
      return;
    }

    final side = details.localPosition.dx < constraints.maxWidth / 2
        ? 'host'
        : 'guest';
    // One tap should count once in PK score. The extra hearts are only visual.
    widget.onTap(side);

    final baseColor = side == 'host'
        ? LiveRoomScreen._primaryBlue
        : LiveRoomScreen._accentRed;
    final palette = <Color>[
      baseColor,
      const Color(0xFFFF4F8B),
      const Color(0xFFFFD15C),
      Colors.white,
    ];
    final newBursts = List<_LivePkHeartBurstData>.generate(_heartsPerTap, (
      index,
    ) {
      final spread = Offset(
        (_random.nextDouble() - 0.5) * 58,
        (_random.nextDouble() - 0.5) * 34,
      );
      return _LivePkHeartBurstData(
        id: _nextBurstId++,
        position: details.localPosition + spread,
        color: palette[index % palette.length],
        size: 24 + (_random.nextDouble() * 18),
        lift: 74 + (_random.nextDouble() * 92),
        driftX: (_random.nextDouble() - 0.5) * 76,
        rotation: (_random.nextDouble() - 0.5) * 0.85,
        duration: Duration(milliseconds: 760 + _random.nextInt(280)),
      );
    });
    setState(() {
      _bursts.addAll(newBursts);
      if (_bursts.length > _maxActiveHearts) {
        _bursts.removeRange(0, _bursts.length - _maxActiveHearts);
      }
    });
  }

  void _removeBurst(int id) {
    if (!mounted) {
      return;
    }
    setState(() {
      _bursts.removeWhere((burst) => burst.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Semantics(
                label: 'live-pk-like-surface',
                button: true,
                enabled: widget.enabled,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) => _handleTapDown(details, constraints),
                ),
              ),
            ),
            for (final burst in _bursts)
              _LivePkHeartBurst(
                key: ValueKey(burst.id),
                data: burst,
                onCompleted: () => _removeBurst(burst.id),
              ),
          ],
        );
      },
    );
  }
}

class _LivePkHeartBurstData {
  const _LivePkHeartBurstData({
    required this.id,
    required this.position,
    required this.color,
    required this.size,
    required this.lift,
    required this.driftX,
    required this.rotation,
    required this.duration,
  });

  final int id;
  final Offset position;
  final Color color;
  final double size;
  final double lift;
  final double driftX;
  final double rotation;
  final Duration duration;
}

class _LivePkHeartBurst extends StatelessWidget {
  const _LivePkHeartBurst({
    super.key,
    required this.data,
    required this.onCompleted,
  });

  final _LivePkHeartBurstData data;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: data.position.dx - (data.size / 2),
      top: data.position.dy - (data.size / 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: data.duration,
        curve: Curves.easeOutCubic,
        onEnd: onCompleted,
        builder: (context, value, child) {
          return Opacity(
            opacity: (1 - value).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(data.driftX * value, -data.lift * value),
              child: Transform.rotate(
                angle: data.rotation * value,
                child: Transform.scale(
                  scale: 0.62 + (0.68 * value),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: Icon(
          Icons.favorite_rounded,
          color: data.color,
          size: data.size,
          shadows: const [
            Shadow(color: Colors.black54, blurRadius: 10),
            Shadow(color: Colors.white70, blurRadius: 4),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomChatPanel extends StatelessWidget {
  const _LiveRoomChatPanel({
    required this.comments,
    required this.onProfileTap,
  });

  final List<_LiveRoomComment> comments;
  final ValueChanged<_LiveRoomComment> onProfileTap;

  @override
  Widget build(BuildContext context) {
    final visibleComments = comments.length > 28
        ? comments.sublist(comments.length - 28)
        : comments;

    return DecoratedBox(
      key: const ValueKey('live-room-screen'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0x99000000), Color(0x61000000), Color(0x16000000)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x59000000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'نصائح إدارية: احترم القوانين. سيتم حظر أي محتوى مسيء أو عنيف أو مخالف.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                reverse: true,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: visibleComments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final comment =
                      visibleComments[visibleComments.length - 1 - index];
                  return _LiveRoomCommentRow(
                    comment: comment,
                    onProfileTap: () => onProfileTap(comment),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomCommentRow extends StatelessWidget {
  const _LiveRoomCommentRow({
    required this.comment,
    required this.onProfileTap,
  });

  final _LiveRoomComment comment;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'live-comment-profile-${comment.name}',
              button: true,
              child: InkWell(
                onTap: onProfileTap,
                customBorder: const CircleBorder(),
                child: ClipOval(
                  child: ResolvedImage(
                    path: comment.avatarAsset,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x61000000),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: onProfileTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            comment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white70,
                              decorationThickness: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.message,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomComposer extends StatelessWidget {
  const _LiveRoomComposer({
    required this.controller,
    required this.focusNode,
    required this.onChatTap,
    required this.onGiftTap,
    required this.onRoomToolsTap,
    required this.onPeopleTap,
    required this.onSendTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChatTap;
  final VoidCallback onGiftTap;
  final VoidCallback onRoomToolsTap;
  final VoidCallback onPeopleTap;
  final VoidCallback onSendTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LiveRoomActionButton(
          icon: Icons.mail_rounded,
          semanticsLabel: 'live-room-chat-action',
          onTap: onChatTap,
        ),
        const SizedBox(width: 5),
        _LiveRoomGiftActionButton(onTap: onGiftTap),
        const SizedBox(width: 5),
        _LiveRoomActionButton(
          icon: Icons.grid_view_rounded,
          semanticsLabel: 'live-room-tools-action',
          onTap: onRoomToolsTap,
        ),
        const SizedBox(width: 5),
        _LiveRoomActionButton(
          icon: Icons.people_alt_rounded,
          semanticsLabel: 'live-room-people-action',
          onTap: onPeopleTap,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
            decoration: BoxDecoration(
              color: const Color(0xA3000000),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x33FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textAlign: TextAlign.right,
                      textInputAction: TextInputAction.send,
                      maxLines: 1,
                      onSubmitted: (_) => onSendTap(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'اكتب تعليقك هنا',
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSendTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: LiveRoomScreen._primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/live150_send.png',
                          width: 18,
                          height: 18,
                        ),
                      ),
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

class _LiveRoomActionButton extends StatelessWidget {
  const _LiveRoomActionButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width < 340 ? 32.0 : 36.0;

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: LiveRoomScreen._primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.48),
        ),
      ),
    );
  }
}

class _LiveRoomGiftActionButton extends StatelessWidget {
  const _LiveRoomGiftActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width < 340 ? 32.0 : 36.0;

    return Semantics(
      label: 'live-room-gift-action',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: LiveRoomScreen._primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/images/live150_gift.png',
              width: size * 0.49,
              height: size * 0.49,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveGiftEffectOverlay extends StatelessWidget {
  const _LiveGiftEffectOverlay({required this.event});

  final LiveGiftEventData event;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          right: 14,
          left: 78,
          bottom: 172,
          child: _LiveGiftSenderToast(event: event),
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('live-gift-burst-${event.id}'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 920),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final scale =
                  0.72 + (math.sin(value * math.pi) * 0.22) + value * 0.12;
              final dy = -18 * value;
              final rotation = (1 - value) * -0.09;
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(scale: scale, child: child),
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 292,
              height: 292,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _LiveGiftParticle(angle: -2.6, distance: 118, size: 10),
                  const _LiveGiftParticle(angle: -1.95, distance: 134, size: 7),
                  const _LiveGiftParticle(angle: -1.1, distance: 126, size: 12),
                  const _LiveGiftParticle(angle: -0.35, distance: 132, size: 8),
                  const _LiveGiftParticle(angle: 0.5, distance: 112, size: 11),
                  const _LiveGiftParticle(angle: 1.35, distance: 124, size: 7),
                  const _LiveGiftParticle(angle: 2.15, distance: 128, size: 10),
                  Container(
                    width: 216,
                    height: 216,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.34),
                          Colors.white.withValues(alpha: 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 186,
                    height: 186,
                    child: ResolvedImage(
                      path: event.gift.effectAssetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    bottom: 33,
                    child: _LiveGiftComboBadge(
                      quantity: event.quantity,
                      totalCoins: event.totalPriceCoins,
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

class _LiveGiftSenderToast extends StatelessWidget {
  const _LiveGiftSenderToast({required this.event});

  final LiveGiftEventData event;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('live-gift-toast-${event.id}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * 72, 0),
            child: child,
          ),
        );
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: 54,
          padding: const EdgeInsetsDirectional.fromSTEB(5, 5, 8, 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xE61B2431), Color(0xC8285F98)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipOval(
                child: ResolvedImage(
                  path: event.senderAvatarAsset,
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'أرسل ${event.gift.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFE7A3),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 42,
                height: 42,
                child: ResolvedImage(
                  path: event.gift.assetPath,
                  fit: BoxFit.contain,
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

class _LiveGiftComboBadge extends StatelessWidget {
  const _LiveGiftComboBadge({required this.quantity, required this.totalCoins});

  final int quantity;
  final int totalCoins;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2FFCE37),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            'x$quantity  •  $totalCoins Coin',
            style: const TextStyle(
              color: Color(0xFF1C2530),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveGiftParticle extends StatelessWidget {
  const _LiveGiftParticle({
    required this.angle,
    required this.distance,
    required this.size,
  });

  final double angle;
  final double distance;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 980),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final dx = math.cos(angle) * distance * value;
        final dy = math.sin(angle) * distance * value;
        return Opacity(
          opacity: (1 - (value * 0.75)).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, dy), child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFD646),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD646).withValues(alpha: 0.58),
              blurRadius: 14,
            ),
          ],
        ),
        child: SizedBox(width: size, height: size),
      ),
    );
  }
}

class _LiveRoomToolsSheet extends StatelessWidget {
  const _LiveRoomToolsSheet({
    required this.onDismiss,
    required this.isMuted,
    required this.canEndLive,
    required this.isEndingLive,
    required this.onMuteTap,
    required this.onReportTap,
    required this.onShareTap,
    required this.onEffectsTap,
    required this.onEndLiveTap,
  });

  final VoidCallback onDismiss;
  final bool isMuted;
  final bool canEndLive;
  final bool isEndingLive;
  final VoidCallback onMuteTap;
  final VoidCallback onReportTap;
  final VoidCallback onShareTap;
  final VoidCallback onEffectsTap;
  final VoidCallback onEndLiveTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-tools-sheet'),
        height: canEndLive ? 132 : 118,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 6),
            Center(
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اداة الغرفة',
                  style: TextStyle(
                    color: LiveRoomScreen._primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LiveRoomToolAction(
                    icon: isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    label: isMuted ? 'تشغيل الصوت' : 'كتم الصوت',
                    semanticsLabel: 'live-room-tool-mute',
                    onTap: onMuteTap,
                  ),
                  _LiveRoomToolAction(
                    icon: Icons.shield_outlined,
                    label: 'ابلاغ',
                    semanticsLabel: 'live-room-tool-report',
                    onTap: onReportTap,
                  ),
                  _LiveRoomToolAction(
                    icon: Icons.share_outlined,
                    label: 'شارك',
                    semanticsLabel: 'live-room-tool-share',
                    onTap: onShareTap,
                  ),
                  _LiveRoomToolAction(
                    icon: Icons.auto_awesome_outlined,
                    label: 'اعدادات التاثير',
                    semanticsLabel: 'live-room-tool-effects',
                    onTap: onEffectsTap,
                  ),
                  if (canEndLive)
                    _LiveRoomToolAction(
                      icon: Icons.power_settings_new_rounded,
                      label: isEndingLive ? 'جاري الإنهاء' : 'إنهاء اللايف',
                      semanticsLabel: 'live-room-tool-end',
                      onTap: isEndingLive ? null : onEndLiveTap,
                      isDanger: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomToolAction extends StatelessWidget {
  const _LiveRoomToolAction({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEDFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDanger
                      ? LiveRoomScreen._accentRed
                      : LiveRoomScreen._primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDanger
                      ? LiveRoomScreen._accentRed
                      : LiveRoomScreen._primaryBlue,
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

class _LiveRoomComment {
  const _LiveRoomComment({
    required this.userId,
    required this.name,
    required this.message,
    required this.avatarAsset,
  });

  final int? userId;
  final String name;
  final String message;
  final String avatarAsset;
}

class _LiveRoomEffectsToolbar extends StatelessWidget {
  const _LiveRoomEffectsToolbar({
    required this.onGiftTap,
    required this.onSettingsTap,
    required this.onPkTap,
    required this.onNotificationTap,
    required this.onGridTap,
    required this.onPeopleTap,
    required this.onMessageTap,
  });

  final VoidCallback onGiftTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onPkTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onGridTap;
  final VoidCallback onPeopleTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-gift'),
            semanticsLabel: 'live-room-effects-gift',
            onTap: onGiftTap,
            child: Image.asset(
              'assets/images/live150_gift.png',
              width: 17,
              height: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-settings'),
            semanticsLabel: 'live-room-effects-settings',
            onTap: onSettingsTap,
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-pk'),
            semanticsLabel: 'live-room-effects-pk',
            onTap: onPkTap,
            child: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'P',
                    style: TextStyle(
                      color: Color(0xFFFF9000),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: 'K',
                    style: TextStyle(
                      color: Color(0xFF6D9BFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-notification'),
            semanticsLabel: 'live-room-effects-notification',
            onTap: onNotificationTap,
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-grid'),
            semanticsLabel: 'live-room-effects-grid',
            onTap: onGridTap,
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-people'),
            semanticsLabel: 'live-room-effects-people',
            onTap: onPeopleTap,
            child: const Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          _LiveRoomEffectCircle(
            key: const ValueKey('live-room-effects-message'),
            semanticsLabel: 'live-room-effects-message',
            onTap: onMessageTap,
            child: const Icon(
              Icons.message_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomEffectSettingsPanel extends StatelessWidget {
  const _LiveRoomEffectSettingsPanel({
    required this.onDismiss,
    required this.sections,
    required this.isHost,
    required this.onActionTap,
  });

  final VoidCallback onDismiss;
  final List<LiveActionSectionData> sections;
  final bool isHost;
  final ValueChanged<LiveActionButtonData> onActionTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final panelHeight = math.min(
      428.0,
      math.max(320.0, (size.height - bottomPadding) * 0.48),
    );
    final modeTitle = isHost ? 'وضع صاحب البث' : 'وضع المشاهد';
    final modeSubtitle = isHost
        ? 'أدوات البث المباشر والتأثيرات تعمل على كاميرتك وصوتك الآن.'
        : 'تقدر تستخدم أدوات المشاهدة، وأدوات صاحب البث تظهر مقفولة للتوضيح.';

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-effect-settings-panel'),
        height: panelHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              key: const ValueKey('live-room-effect-settings-dismiss'),
              onTap: onDismiss,
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إعدادات التأثير واللايف',
                            style: TextStyle(
                              color: LiveRoomScreen._primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            modeSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF5F7288),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FB),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFD2E3F7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHost
                                ? Icons.videocam_rounded
                                : Icons.visibility_rounded,
                            color: LiveRoomScreen._primaryBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            modeTitle,
                            style: const TextStyle(
                              color: LiveRoomScreen._primaryBlue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    ...sections.expand(
                      (section) => [
                        _LiveRoomManagementSection(
                          title: section.title,
                          actions: section.actions,
                          isHost: isHost,
                          onActionTap: onActionTap,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomNotificationsSheet extends StatelessWidget {
  const _LiveRoomNotificationsSheet({required this.notifications});

  final List<LiveNotificationData> notifications;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.64;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إشعارات اللايف',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: LiveRoomScreen._primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'لا توجد إشعارات الآن',
                      style: TextStyle(
                        color: LiveRoomScreen._primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        title: Text(
                          notification.title,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${notification.message}\n${notification.createdAtLabel}',
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveRoomGiftSheet extends StatefulWidget {
  const _LiveRoomGiftSheet({
    required this.repository,
    required this.roomId,
    required this.onGiftFocused,
  });

  final LiveRepository repository;
  final int roomId;
  final ValueChanged<LiveGiftItemData> onGiftFocused;

  @override
  State<_LiveRoomGiftSheet> createState() => _LiveRoomGiftSheetState();
}

class _LiveRoomGiftSheetState extends State<_LiveRoomGiftSheet> {
  LiveGiftPanelData? _panel;
  int? _selectedGiftId;
  int _quantity = 1;
  String _selectedCategory = 'الكل';
  bool _isLoading = true;
  bool _isSending = false;
  final Set<String> _preloadedVisualPaths = <String>{};

  List<String> get _categories {
    final gifts = _panel?.gifts ?? const <LiveGiftItemData>[];
    final categories = <String>['الكل'];
    for (final gift in gifts) {
      final category = gift.category.trim();
      if (category.isNotEmpty && !categories.contains(category)) {
        categories.add(category);
      }
    }
    return categories;
  }

  List<LiveGiftItemData> get _visibleGifts {
    final gifts = _panel?.gifts ?? const <LiveGiftItemData>[];
    if (_selectedCategory == 'الكل') {
      return gifts;
    }

    return gifts
        .where((gift) => gift.category.trim() == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _openWallet() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushNamed(AppRoutes.profileWallet);
      }
    });
  }

  Future<void> _load() async {
    final panel = await widget.repository.loadGiftPanel(roomId: widget.roomId);
    if (!mounted) {
      return;
    }
    setState(() {
      _panel = panel;
      _isLoading = false;
    });
    _precachePanelGifts(panel.gifts);
  }

  Future<void> _send() async {
    final panel = _panel;
    final selectedGiftId = _selectedGiftId;
    if (panel == null || selectedGiftId == null) {
      return;
    }
    LiveGiftItemData? selectedGift;
    for (final gift in panel.gifts) {
      if (gift.id == selectedGiftId) {
        selectedGift = gift;
        break;
      }
    }
    if (selectedGift != null) {
      widget.onGiftFocused(selectedGift);
    }

    setState(() {
      _isSending = true;
    });
    try {
      final result = await widget.repository.sendGift(
        roomId: widget.roomId,
        giftId: selectedGiftId,
        quantity: _quantity,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxHeight = math.min(
      size.height - 36,
      math.max(430.0, size.height * 0.78),
    );
    final visibleGifts = _visibleGifts;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: LiveRoomScreen._primaryBlue,
                    tooltip: 'إغلاق',
                  ),
                  const Spacer(),
                  const Text(
                    'إرسال هدية',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: LiveRoomScreen._primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (_panel != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _openWallet,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_rounded,
                          color: LiveRoomScreen._primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'شحن',
                          style: TextStyle(
                            color: LiveRoomScreen._primaryBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'رصيدك: ${_panel!.walletCoinsBalance} Coin',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: LiveRoomScreen._primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!_isLoading)
                _LiveGiftCategoryTabs(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onSelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                      _selectedGiftId = null;
                    });
                  },
                ),
              if (!_isLoading) const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleGifts.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'لا توجد هدايا في هذا القسم',
                      style: TextStyle(
                        color: LiveRoomScreen._primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = math
                          .max(
                            3,
                            math.min(5, (constraints.maxWidth / 88).floor()),
                          )
                          .toInt();
                      return GridView.builder(
                        itemCount: visibleGifts.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.66,
                        ),
                        itemBuilder: (context, index) {
                          final gift = visibleGifts[index];
                          final isSelected = gift.id == _selectedGiftId;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedGiftId = gift.id;
                              });
                              widget.onGiftFocused(gift);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFDCEBFA)
                                    : const Color(0xFFF7FAFD),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? LiveRoomScreen._primaryBlue
                                      : Colors.transparent,
                                  width: 1.4,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ResolvedImage(
                                      path: gift.assetPath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    gift.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${gift.priceCoins} Coin',
                                    style: const TextStyle(
                                      color: LiveRoomScreen._primaryBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (gift.isAnimated || gift.hasSound) ...[
                                    const SizedBox(height: 3),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 3,
                                      children: [
                                        if (gift.isAnimated)
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: LiveRoomScreen._primaryBlue,
                                            size: 12,
                                          ),
                                        if (gift.hasSound)
                                          const Icon(
                                            Icons.volume_up_rounded,
                                            color: LiveRoomScreen._primaryBlue,
                                            size: 12,
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              _LiveGiftQuantityPresets(
                quantity: _quantity,
                onSelected: (quantity) {
                  setState(() {
                    _quantity = quantity;
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _quantity > 1
                        ? () => setState(() {
                            _quantity -= 1;
                          })
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: LiveRoomScreen._primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _quantity < 999
                        ? () => setState(() {
                            _quantity += 1;
                          })
                        : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedGiftId == null || _isSending
                            ? null
                            : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LiveRoomScreen._primaryBlue,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(
                          _isSending ? 'جارٍ الإرسال...' : 'إرسال الآن',
                        ),
                      ),
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

  void _precachePanelGifts(List<LiveGiftItemData> gifts) {
    for (final gift in gifts) {
      _precacheGiftVisual(gift.assetPath);
      _precacheGiftVisual(gift.effectAssetPath);
    }
  }

  void _precacheGiftVisual(String path) {
    final resolvedPath = path.trim();
    if (resolvedPath.isEmpty || !_preloadedVisualPaths.add(resolvedPath)) {
      return;
    }

    unawaited(precacheResolvedImage(context, resolvedPath));
  }
}

class _LiveGiftCategoryTabs extends StatelessWidget {
  const _LiveGiftCategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category == selectedCategory;
            return ChoiceChip(
              selected: isSelected,
              label: Text(category),
              onSelected: (_) => onSelected(category),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : LiveRoomScreen._primaryBlue,
                fontWeight: FontWeight.w800,
              ),
              selectedColor: LiveRoomScreen._primaryBlue,
              backgroundColor: const Color(0xFFEAF2FB),
              side: BorderSide(
                color: isSelected
                    ? LiveRoomScreen._primaryBlue
                    : const Color(0xFFD2DFF2),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiveGiftQuantityPresets extends StatelessWidget {
  const _LiveGiftQuantityPresets({
    required this.quantity,
    required this.onSelected,
  });

  final int quantity;
  final ValueChanged<int> onSelected;

  static const List<int> _values = [1, 10, 99, 199, 999];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _values.map((value) {
          final isSelected = value == quantity;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? LiveRoomScreen._primaryBlue
                    : const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? LiveRoomScreen._primaryBlue
                      : const Color(0xFFD2DFF2),
                ),
              ),
              child: Text(
                'x$value',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : LiveRoomScreen._primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LiveActionDetailsSheet extends StatelessWidget {
  const _LiveActionDetailsSheet({required this.action, required this.message});

  final LiveActionButtonData action;
  final String message;

  @override
  Widget build(BuildContext context) {
    final title = action.detailTitle.trim().isEmpty
        ? action.label.replaceAll(r'\n', ' ')
        : action.detailTitle;
    final body = action.detailBody.trim().isEmpty
        ? 'يمكن التحكم في هذا الزر وتفاصيله من لوحة التحكم.'
        : action.detailBody;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCEDFF),
                      shape: BoxShape.circle,
                    ),
                    child: action.iconAsset.trim().isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: ResolvedImage(
                              path: action.iconAsset,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Icon(
                            Icons.widgets_rounded,
                            color: LiveRoomScreen._primaryBlue,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: LiveRoomScreen._primaryBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFF24364B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: LiveRoomScreen._primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LiveRoomScreen._primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('تمام'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveRoomReportSheet extends StatefulWidget {
  const _LiveRoomReportSheet();

  @override
  State<_LiveRoomReportSheet> createState() => _LiveRoomReportSheetState();
}

class _LiveRoomReportSheetState extends State<_LiveRoomReportSheet> {
  static const List<String> _reasons = [
    'محتوى غير مناسب',
    'إزعاج أو سبام',
    'إساءة أو تنمر',
    'مخالفة للقوانين',
  ];

  String _selectedReason = _reasons.first;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'الإبلاغ عن اللايف',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: LiveRoomScreen._primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ..._reasons.map(
              (reason) => ListTile(
                onTap: () {
                  setState(() {
                    _selectedReason = reason;
                  });
                },
                title: Text(reason, textAlign: TextAlign.right),
                trailing: Icon(
                  _selectedReason == reason
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: LiveRoomScreen._primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selectedReason),
              style: ElevatedButton.styleFrom(
                backgroundColor: LiveRoomScreen._primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('إرسال البلاغ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePkInviteSheet extends StatefulWidget {
  const _LivePkInviteSheet({required this.repository, required this.roomId});

  final LiveRepository repository;
  final int roomId;

  @override
  State<_LivePkInviteSheet> createState() => _LivePkInviteSheetState();
}

class _LivePkInviteSheetState extends State<_LivePkInviteSheet> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<LivePkRecipientData>> _recipientsFuture;
  int? _selectedRecipientId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _recipientsFuture = widget.repository.listPkRecipients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    setState(() {
      _recipientsFuture = widget.repository.listPkRecipients(query: value);
    });
  }

  Future<void> _sendInvite() async {
    final selectedRecipientId = _selectedRecipientId;
    if (selectedRecipientId == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });
    try {
      await widget.repository.sendPkInvite(
        roomId: widget.roomId,
        recipientUserId: selectedRecipientId,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال دعوة PK')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تحدي الأصدقاء',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: LiveRoomScreen._primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'ابحث عن صديق',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF3F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: FutureBuilder<List<LivePkRecipientData>>(
                  future: _recipientsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final recipients =
                        snapshot.data ?? const <LivePkRecipientData>[];
                    if (recipients.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('لا يوجد أصدقاء مطابقون')),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: recipients.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final recipient = recipients[index];
                        final isSelected = recipient.id == _selectedRecipientId;
                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedRecipientId = recipient.id;
                            });
                          },
                          selected: isSelected,
                          leading: ClipOval(
                            child: Image.asset(
                              recipient.avatarAsset,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            recipient.name,
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            recipient.subtitle,
                            textAlign: TextAlign.right,
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: LiveRoomScreen._primaryBlue,
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _selectedRecipientId == null || _isSending
                    ? null
                    : _sendInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LiveRoomScreen._primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isSending ? 'جارٍ الإرسال...' : 'إرسال الدعوة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveRoomManagementSection extends StatelessWidget {
  const _LiveRoomManagementSection({
    required this.title,
    required this.actions,
    required this.isHost,
    required this.onActionTap,
  });

  final String title;
  final List<LiveActionButtonData> actions;
  final bool isHost;
  final ValueChanged<LiveActionButtonData> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth < 330 ? 4 : 5;
              final itemWidth =
                  ((constraints.maxWidth - ((columnCount - 1) * 12)) /
                          columnCount)
                      .clamp(54.0, 72.0);

              return Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: actions
                    .map(
                      (action) => _LiveRoomManagementItem(
                        action: action,
                        enabled: isHost || !action.requiresHost,
                        width: itemWidth,
                        onTap: () => onActionTap(action),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LiveRoomManagementItem extends StatelessWidget {
  const _LiveRoomManagementItem({
    required this.action,
    required this.enabled,
    required this.width,
    required this.onTap,
  });

  final LiveActionButtonData action;
  final bool enabled;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = action.label.replaceAll(r'\n', '\n');
    return Semantics(
      label: 'live-room-action-${action.actionKey}',
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCEDFF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: action.iconAsset.trim().isNotEmpty
                            ? ResolvedImage(
                                path: action.iconAsset,
                                width: 25,
                                height: 25,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                _iconForAction(action.iconKind),
                                color: LiveRoomScreen._primaryBlue,
                                size: 24,
                              ),
                      ),
                    ),
                    if (!enabled)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD2E3F7)),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: LiveRoomScreen._primaryBlue,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: label.contains('\n') ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LiveRoomScreen._primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForAction(String iconKind) {
    switch (iconKind) {
      case 'beauty':
        return Icons.auto_awesome_rounded;
      case 'sticker':
        return Icons.emoji_emotions_outlined;
      case 'interface':
        return Icons.photo_camera_outlined;
      case 'mute':
        return Icons.mic_off_outlined;
      case 'headset':
        return Icons.headset_rounded;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'welcome':
        return Icons.mark_chat_read_outlined;
      case 'new_user':
        return Icons.person_add_alt_1_rounded;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'ranking':
        return Icons.leaderboard_outlined;
      case 'game':
        return Icons.sports_esports_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'pk':
        return Icons.bolt_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }
}

class _LiveRoomViewersPanel extends StatelessWidget {
  const _LiveRoomViewersPanel({
    required this.onDismiss,
    required this.onTopSupportersTap,
  });

  final VoidCallback onDismiss;
  final VoidCallback onTopSupportersTap;

  @override
  Widget build(BuildContext context) {
    final room = _LiveRoomDataScope.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-viewers-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              'المشاهدين',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: room.viewers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final viewer = room.viewers[index];
                  return _LiveRoomViewerRow(
                    rank: viewer.rank,
                    name: viewer.name,
                    avatarAsset: viewer.avatarAsset,
                    isTopSupporter: viewer.isTopSupporter,
                    onTopSupportersTap: onTopSupportersTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomViewerRow extends StatelessWidget {
  const _LiveRoomViewerRow({
    required this.rank,
    required this.name,
    required this.avatarAsset,
    required this.isTopSupporter,
    required this.onTopSupportersTap,
  });

  final int rank;
  final String name;
  final String avatarAsset;
  final bool isTopSupporter;
  final VoidCallback onTopSupportersTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Text(
            '$rank',
            style: const TextStyle(
              color: LiveRoomScreen._primaryBlue,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 14),
          ClipOval(
            child: Image.asset(
              avatarAsset,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isTopSupporter) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'live-room-top-supporters-entry',
                    button: true,
                    child: GestureDetector(
                      onTap: onTopSupportersTap,
                      child: Container(
                        width: 61,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFBEAC), Color(0xFFFFBF00)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'افضل الداعمين',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomContributionPanel extends StatelessWidget {
  const _LiveRoomContributionPanel({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final room = _LiveRoomDataScope.of(context);
    final supporters = room.supporters;

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-contribution-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              'قائمة المساهمات لهذه الجولة',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: supporters.isEmpty
                  ? Column(
                      children: [
                        const Spacer(),
                        Image.asset(
                          'assets/images/live155_empty_state.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'لا يوجد الان بيانات',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: supporters.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final supporter = supporters[index];
                        return Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            children: [
                              Text(
                                '${supporter.rank}',
                                style: const TextStyle(
                                  color: LiveRoomScreen._primaryBlue,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ClipOval(
                                child: Image.asset(
                                  supporter.avatarAsset,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      supporter.name,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      supporter.coinsLabel,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: LiveRoomScreen._primaryBlue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(height: 1, color: const Color(0xFFD9D9D9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 10, 40, 9),
              child: Row(
                children: [
                  Expanded(
                    child: _LiveRoomContributionStat(
                      value: '${room.contributionDiamondsTotal}',
                      label: 'الهدية الاجمالية',
                      icon: Image.asset(
                        'assets/images/live155_diamond.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: _LiveRoomContributionStat(
                      value: '${room.contributionSenderCount}',
                      label: 'عدد المرسلين',
                      icon: const Icon(
                        Icons.groups_2_outlined,
                        color: LiveRoomScreen._primaryBlue,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomContributionStat extends StatelessWidget {
  const _LiveRoomContributionStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            icon,
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFBEBEBE),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LiveRoomPkPanel extends StatelessWidget {
  const _LiveRoomPkPanel({
    required this.onDismiss,
    required this.isPkVisible,
    required this.onStartMatchingTap,
    required this.onEndPkTap,
    required this.onSettingsTap,
    required this.onChallengeFriendsTap,
  });

  final VoidCallback onDismiss;
  final bool isPkVisible;
  final VoidCallback onStartMatchingTap;
  final VoidCallback onEndPkTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onChallengeFriendsTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-pk-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 141,
                height: 8,
                decoration: BoxDecoration(
                  color: LiveRoomScreen._primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '1v1 PK',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: _LiveRoomPkCard(
                backgroundColor: Color(0xFFF2496D),
                leftColor: Color(0xFF9345CF),
                title: 'نمط المطابقة',
                description:
                    'سيطابقك النظام مع خصوم ذوي قوة مماثلة\nولك.افز واحصل علي نقاط المعركة',
                buttonText: isPkVisible ? 'إنهاء PK' : 'بدء المطابقة',
                showPkMark: true,
                onButtonTap: isPkVisible ? onEndPkTap : onStartMatchingTap,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: _LiveRoomPkCard(
                backgroundColor: Color(0xFF3E18C5),
                leftColor: Color(0xFF3E18C5),
                title: 'وضع الدعوة',
                description: 'دعوة اصدقائك لا يجلب نقاط المعركة',
                buttonText: 'تحدي الاصدقاء',
                showPkMark: false,
                onButtonTap: onChallengeFriendsTap,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onSettingsTap,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('إعدادات PK'),
              style: TextButton.styleFrom(
                foregroundColor: LiveRoomScreen._primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomPkCard extends StatelessWidget {
  const _LiveRoomPkCard({
    required this.backgroundColor,
    required this.leftColor,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.showPkMark,
    required this.onButtonTap,
  });

  final Color backgroundColor;
  final Color leftColor;
  final String title;
  final String description;
  final String buttonText;
  final bool showPkMark;
  final VoidCallback onButtonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 97,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                color: leftColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (showPkMark)
            const Positioned(
              left: 12,
              top: 16,
              child: Text(
                'PK',
                style: TextStyle(
                  color: Color(0xFFFFA700),
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onButtonTap,
                        child: Container(
                          width: 87,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomPkLiveSettingsPanel extends StatelessWidget {
  const _LiveRoomPkLiveSettingsPanel({
    required this.onDismiss,
    required this.talkPermission,
    required this.onTalkPermissionChanged,
    required this.partyInvitePermission,
    required this.onPartyInvitePermissionChanged,
    required this.voiceRoomInvitePermission,
    required this.onVoiceRoomInvitePermissionChanged,
    required this.chatPermission,
    required this.onChatPermissionChanged,
    required this.battleDuration,
    required this.onBattleDurationChanged,
  });

  final VoidCallback onDismiss;
  final String talkPermission;
  final ValueChanged<String> onTalkPermissionChanged;
  final String partyInvitePermission;
  final ValueChanged<String> onPartyInvitePermissionChanged;
  final String voiceRoomInvitePermission;
  final ValueChanged<String> onVoiceRoomInvitePermissionChanged;
  final String chatPermission;
  final ValueChanged<String> onChatPermissionChanged;
  final String battleDuration;
  final ValueChanged<String> onBattleDurationChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('live-room-pk-settings-panel'),
        height: 369,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 141,
                  height: 8,
                  decoration: BoxDecoration(
                    color: LiveRoomScreen._primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(19, 15, 19, 0),
              child: Text(
                'اعدادات الايف',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LiveRoomPermissionRow(
              title: 'من يستطيع التحدث في حياتي',
              selectedValue: talkPermission,
              onChanged: onTalkPermissionChanged,
            ),
            _LiveRoomPermissionRow(
              title: 'من يمكنه دعوتي الي Party',
              selectedValue: partyInvitePermission,
              onChanged: onPartyInvitePermissionChanged,
            ),
            _LiveRoomPermissionRow(
              title: 'من يستطيع دعوتي الي غرفة صوتيه',
              selectedValue: voiceRoomInvitePermission,
              onChanged: onVoiceRoomInvitePermissionChanged,
            ),
            _LiveRoomPermissionRow(
              title: 'من يمكنه الدردشة',
              selectedValue: chatPermission,
              onChanged: onChatPermissionChanged,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(19, 10, 19, 0),
              child: Text(
                'مدة المعركة',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 6, 19, 0),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LiveRoomDurationOption(
                      label: '3د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                    _LiveRoomDurationOption(
                      label: '5د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                    _LiveRoomDurationOption(
                      label: '15د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                    _LiveRoomDurationOption(
                      label: '30د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                    _LiveRoomDurationOption(
                      label: '60د',
                      selectedValue: battleDuration,
                      onChanged: onBattleDurationChanged,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(height: 2, color: const Color(0xFFE8E8E8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 18, 47, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _LiveRoomFooterAction(
                    icon: Icons.mic_rounded,
                    semanticsLabel: 'live-room-pk-settings-mic',
                  ),
                  _LiveRoomFooterAction(
                    icon: Icons.music_note_rounded,
                    semanticsLabel: 'live-room-pk-settings-music',
                  ),
                  _LiveRoomFooterAction(
                    icon: Icons.camera_alt_rounded,
                    semanticsLabel: 'live-room-pk-settings-camera',
                  ),
                  _LiveRoomFooterAction(
                    icon: Icons.grid_view_rounded,
                    semanticsLabel: 'live-room-pk-settings-grid',
                  ),
                  _LiveRoomFooterAction(
                    icon: Icons.videocam_off_rounded,
                    semanticsLabel: 'live-room-pk-settings-camera-off',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRoomPermissionRow extends StatelessWidget {
  const _LiveRoomPermissionRow({
    required this.title,
    required this.selectedValue,
    required this.onChanged,
  });

  final String title;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 0, 19, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _LiveRoomRadioOption(
                  label: 'شبكتي',
                  selected: selectedValue == 'شبكتي',
                  onTap: () => onChanged('شبكتي'),
                ),
                const SizedBox(width: 26),
                _LiveRoomRadioOption(
                  label: 'عند الطلب',
                  selected: selectedValue == 'عند الطلب',
                  onTap: () => onChanged('عند الطلب'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomRadioOption extends StatelessWidget {
  const _LiveRoomRadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: selected ? LiveRoomScreen._primaryBlue : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: LiveRoomScreen._primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomDurationOption extends StatelessWidget {
  const _LiveRoomDurationOption({
    required this.label,
    required this.selectedValue,
    required this.onChanged,
  });

  final String label;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = label == selectedValue;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: selected ? LiveRoomScreen._primaryBlue : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: LiveRoomScreen._primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoomFooterAction extends StatelessWidget {
  const _LiveRoomFooterAction({
    required this.icon,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFDCEDFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: LiveRoomScreen._primaryBlue, size: 24),
      ),
    );
  }
}

class _LiveRoomEffectCircle extends StatelessWidget {
  const _LiveRoomEffectCircle({
    super.key,
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            color: LiveRoomScreen._primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
