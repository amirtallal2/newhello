import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/room_audio_repository.dart';

enum RoomAudioConnectionState {
  idle,
  connecting,
  disabled,
  notConfigured,
  permissionDenied,
  joined,
  error,
}

final class RoomAudioController {
  RoomAudioController._();

  static final RoomAudioController instance = RoomAudioController._();

  final ValueNotifier<RoomAudioSessionData?> session =
      ValueNotifier<RoomAudioSessionData?>(null);
  final ValueNotifier<List<RoomAudioParticipantData>> participants =
      ValueNotifier<List<RoomAudioParticipantData>>(
        <RoomAudioParticipantData>[],
      );
  final ValueNotifier<Set<String>> speakingUserAccounts =
      ValueNotifier<Set<String>>(<String>{});
  final ValueNotifier<RoomAudioConnectionState> connectionState =
      ValueNotifier<RoomAudioConnectionState>(RoomAudioConnectionState.idle);
  final ValueNotifier<String?> statusMessage = ValueNotifier<String?>(null);

  RtcEngine? _engine;
  RtcEngineEventHandler? _eventHandler;
  Timer? _heartbeatTimer;
  String? _engineAppId;
  int? _activeRoomId;
  bool _joinedRtc = false;
  bool _isConnecting = false;
  final Map<int, String> _uidToUserAccount = <int, String>{};

  bool get hasJoinedRtc => _joinedRtc;
  int? get activeRoomId => _activeRoomId;

  Future<void> connect(int roomId) async {
    if (_isConnecting) {
      return;
    }

    if (_activeRoomId == roomId && _joinedRtc) {
      return;
    }

    _isConnecting = true;
    try {
      await disconnect(sendLeaveToBackend: _activeRoomId != null);
      _activeRoomId = roomId;
      connectionState.value = RoomAudioConnectionState.connecting;
      statusMessage.value = null;

      final nextSession = await RoomAudioRepository.instance.joinSession(
        roomId,
      );
      _applySession(nextSession);

      if (!nextSession.enabled) {
        connectionState.value = RoomAudioConnectionState.disabled;
        statusMessage.value = 'الغرفة الصوتية غير مفعلة من الإدارة.';
        await _safeLeaveBackend(roomId);
        _activeRoomId = null;
        return;
      }

      if (!nextSession.configured || nextSession.appId.trim().isEmpty) {
        connectionState.value = RoomAudioConnectionState.notConfigured;
        statusMessage.value = 'إعدادات Agora غير مكتملة على السيرفر.';
        await _safeLeaveBackend(roomId);
        _activeRoomId = null;
        return;
      }

      final hasPermission = await _ensureMicrophonePermission();
      if (!hasPermission) {
        connectionState.value = RoomAudioConnectionState.permissionDenied;
        statusMessage.value =
            'يجب السماح بالوصول إلى الميكروفون لتشغيل الغرفة.';
        await _safeLeaveBackend(roomId);
        _activeRoomId = null;
        return;
      }

      await _ensureEngine(nextSession.appId);
      await _joinRtc(nextSession);
      _startHeartbeat();
    } catch (error) {
      await _handleBackendDisconnect(_readableError(error));
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect({bool sendLeaveToBackend = true}) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_engine != null && _joinedRtc) {
      try {
        await _engine!.leaveChannel();
      } catch (_) {}
    }
    _joinedRtc = false;

    final roomId = _activeRoomId;
    _activeRoomId = null;

    if (sendLeaveToBackend && roomId != null) {
      await _safeLeaveBackend(roomId);
    }

    connectionState.value = RoomAudioConnectionState.idle;
    statusMessage.value = null;
    session.value = null;
    participants.value = <RoomAudioParticipantData>[];
    speakingUserAccounts.value = <String>{};
    _uidToUserAccount.clear();
  }

  Future<void> toggleMicrophone() async {
    final currentSession = session.value;
    final roomId = _activeRoomId;
    if (currentSession == null || roomId == null) {
      return;
    }

    if (!currentSession.canPublishMicrophone) {
      statusMessage.value = 'أنت الآن مستمع فقط. ارفع إلى مقعد أولًا.';
      return;
    }

    final updatedSession = await RoomAudioRepository.instance.updateMicrophone(
      roomId: roomId,
      muted: !currentSession.micMuted,
    );
    _applySession(updatedSession);
    await _syncRtcRole(updatedSession);
  }

  Future<void> refreshParticipants() async {
    final roomId = _activeRoomId;
    if (roomId == null) {
      return;
    }

    try {
      participants.value = await RoomAudioRepository.instance.listParticipants(
        roomId,
      );
    } catch (_) {}
  }

  Future<void> _joinRtc(RoomAudioSessionData nextSession) async {
    final engine = _engine;
    if (engine == null) {
      return;
    }

    await engine.enableAudio();
    await engine.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    await engine.joinChannelWithUserAccount(
      token: nextSession.token,
      channelId: nextSession.channelName,
      userAccount: nextSession.userAccount,
      options: _optionsForSession(nextSession),
    );
    await _syncRtcRole(nextSession);
  }

  Future<void> _ensureEngine(String appId) async {
    if (_engine != null && _engineAppId == appId) {
      return;
    }

    if (_engine != null) {
      try {
        if (_eventHandler != null) {
          _engine!.unregisterEventHandler(_eventHandler!);
        }
        await _engine!.release();
      } catch (_) {}
      _engine = null;
      _eventHandler = null;
      _joinedRtc = false;
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        audioScenario: AudioScenarioType.audioScenarioChatroom,
      ),
    );

    final eventHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        _joinedRtc = true;
        connectionState.value = RoomAudioConnectionState.joined;
        statusMessage.value = null;
      },
      onLeaveChannel: (connection, stats) {
        _joinedRtc = false;
        speakingUserAccounts.value = <String>{};
      },
      onLocalUserRegistered: (uid, userAccount) {
        final normalizedAccount = userAccount.trim();
        if (normalizedAccount.isNotEmpty) {
          _uidToUserAccount[uid] = normalizedAccount;
        }
      },
      onUserInfoUpdated: (uid, info) {
        final normalizedAccount = (info.userAccount ?? '').trim();
        if (normalizedAccount.isNotEmpty) {
          _uidToUserAccount[uid] = normalizedAccount;
        }
      },
      onAudioVolumeIndication:
          (connection, speakers, speakerNumber, totalVolume) {
            _handleAudioVolumeIndication(speakers);
          },
      onTokenPrivilegeWillExpire: (connection, token) async {
        await _renewToken();
      },
      onRequestToken: (connection) async {
        await _renewToken();
      },
      onConnectionStateChanged: (connection, state, reason) {
        if (state == ConnectionStateType.connectionStateDisconnected &&
            _activeRoomId != null &&
            connectionState.value != RoomAudioConnectionState.idle) {
          connectionState.value = RoomAudioConnectionState.error;
          statusMessage.value = 'تم قطع الاتصال بالغرفة الصوتية.';
        }
      },
      onError: (err, msg) {
        connectionState.value = RoomAudioConnectionState.error;
        statusMessage.value = msg.isEmpty ? err.name : msg;
      },
    );
    engine.registerEventHandler(eventHandler);

    _engine = engine;
    _eventHandler = eventHandler;
    _engineAppId = appId;
  }

  Future<void> _renewToken() async {
    final roomId = _activeRoomId;
    final engine = _engine;
    if (roomId == null || engine == null) {
      return;
    }

    try {
      final nextSession = await RoomAudioRepository.instance.fetchToken(roomId);
      _applySession(nextSession);
      if (nextSession.token.trim().isNotEmpty) {
        await engine.renewToken(nextSession.token);
        await _syncRtcRole(nextSession);
      }
    } catch (error) {
      await _handleBackendDisconnect(_readableError(error));
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    final roomId = _activeRoomId;
    if (roomId == null) {
      return;
    }

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final activeRoomId = _activeRoomId;
      if (activeRoomId == null) {
        return;
      }

      try {
        final nextSession = await RoomAudioRepository.instance.heartbeat(
          activeRoomId,
        );
        _applySession(nextSession);
        if (_engine != null && _joinedRtc) {
          await _syncRtcRole(nextSession);
        }
      } catch (error) {
        await _handleBackendDisconnect(_readableError(error));
      }
    });
  }

  Future<void> _syncRtcRole(RoomAudioSessionData nextSession) async {
    final engine = _engine;
    if (engine == null) {
      return;
    }

    final clientRole = nextSession.isBroadcaster
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;
    await engine.setClientRole(role: clientRole);
    await engine.updateChannelMediaOptions(_optionsForSession(nextSession));
    await engine.muteLocalAudioStream(
      !nextSession.canPublishMicrophone || nextSession.micMuted,
    );
  }

  ChannelMediaOptions _optionsForSession(RoomAudioSessionData currentSession) {
    return ChannelMediaOptions(
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      clientRoleType: currentSession.isBroadcaster
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
      autoSubscribeAudio: true,
      autoSubscribeVideo: false,
      publishMicrophoneTrack:
          currentSession.canPublishMicrophone && !currentSession.micMuted,
      enableAudioRecordingOrPlayout: true,
      token: currentSession.usesTokens ? currentSession.token : null,
    );
  }

  void _applySession(RoomAudioSessionData nextSession) {
    session.value = nextSession;
    participants.value = nextSession.participants;
  }

  void _handleAudioVolumeIndication(List<AudioVolumeInfo> speakers) {
    final currentSession = session.value;
    if (currentSession == null) {
      return;
    }

    const minSpeakingVolume = 12;
    final activeAccounts = <String>{};

    for (final speaker in speakers) {
      final uid = speaker.uid ?? -1;
      final volume = speaker.volume ?? 0;
      final isLocalSpeaker = uid == 0;
      final isSpeaking = isLocalSpeaker
          ? volume >= minSpeakingVolume || (speaker.vad ?? 0) == 1
          : volume >= minSpeakingVolume;

      if (!isSpeaking) {
        continue;
      }

      final userAccount = isLocalSpeaker
          ? currentSession.userAccount.trim()
          : (_uidToUserAccount[uid] ?? '').trim();
      if (userAccount.isNotEmpty) {
        activeAccounts.add(userAccount);
      }
    }

    speakingUserAccounts.value = activeAccounts;
  }

  Future<bool> _ensureMicrophonePermission() async {
    if (kIsWeb) {
      return true;
    }

    final status = await Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> _safeLeaveBackend(int roomId) async {
    try {
      await RoomAudioRepository.instance.leaveSession(roomId);
    } catch (_) {}
  }

  Future<void> _handleBackendDisconnect(String message) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_engine != null && _joinedRtc) {
      try {
        await _engine!.leaveChannel();
      } catch (_) {}
    }

    _joinedRtc = false;
    _activeRoomId = null;
    session.value = null;
    participants.value = <RoomAudioParticipantData>[];
    speakingUserAccounts.value = <String>{};
    _uidToUserAccount.clear();
    connectionState.value = RoomAudioConnectionState.error;
    statusMessage.value = message;
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
