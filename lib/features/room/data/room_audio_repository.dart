import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

enum RoomAudioParticipantRole { host, speaker, listener }

class RoomAudioParticipantData {
  const RoomAudioParticipantData({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userAccount,
    required this.displayName,
    required this.avatarAsset,
    required this.role,
    required this.seatNumber,
    required this.micMuted,
    required this.status,
    required this.joinedAt,
    required this.lastSeenAt,
  });

  final int id;
  final int roomId;
  final int? userId;
  final String userAccount;
  final String displayName;
  final String avatarAsset;
  final RoomAudioParticipantRole role;
  final int? seatNumber;
  final bool micMuted;
  final String status;
  final String joinedAt;
  final String lastSeenAt;

  factory RoomAudioParticipantData.fromJson(Map<String, dynamic> json) {
    return RoomAudioParticipantData(
      id: _asInt(json['id']),
      roomId: _asInt(json['room_id']),
      userId: json['user_id'] == null ? null : _asInt(json['user_id']),
      userAccount: json['user_account']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Guest',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      role: _roleFromString(json['role']?.toString() ?? 'listener'),
      seatNumber: json['seat_number'] == null
          ? null
          : _asInt(json['seat_number']),
      micMuted: json['mic_muted'] == true || _asInt(json['mic_muted']) == 1,
      status: json['status']?.toString() ?? 'joined',
      joinedAt: json['joined_at']?.toString() ?? '',
      lastSeenAt: json['last_seen_at']?.toString() ?? '',
    );
  }
}

class RoomAudioSessionData {
  const RoomAudioSessionData({
    required this.enabled,
    required this.configured,
    required this.usesTokens,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.tokenExpiresInSeconds,
    required this.userAccount,
    required this.role,
    required this.clientRole,
    required this.seatNumber,
    required this.micMuted,
    required this.participants,
  });

  final bool enabled;
  final bool configured;
  final bool usesTokens;
  final String appId;
  final String channelName;
  final String token;
  final int tokenExpiresInSeconds;
  final String userAccount;
  final RoomAudioParticipantRole role;
  final String clientRole;
  final int? seatNumber;
  final bool micMuted;
  final List<RoomAudioParticipantData> participants;

  bool get isBroadcaster => clientRole == 'broadcaster';
  bool get canPublishMicrophone =>
      role == RoomAudioParticipantRole.host ||
      role == RoomAudioParticipantRole.speaker;

  factory RoomAudioSessionData.fromJson(Map<String, dynamic> json) {
    return RoomAudioSessionData(
      enabled: json['enabled'] == true || _asInt(json['enabled']) == 1,
      configured: json['configured'] == true || _asInt(json['configured']) == 1,
      usesTokens:
          json['uses_tokens'] == true || _asInt(json['uses_tokens']) == 1,
      appId: json['app_id']?.toString() ?? '',
      channelName: json['channel_name']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      tokenExpiresInSeconds: _asInt(
        json['token_expires_in_seconds'],
        fallback: 3600,
      ),
      userAccount: json['user_account']?.toString() ?? '',
      role: _roleFromString(json['role']?.toString() ?? 'listener'),
      clientRole: json['client_role']?.toString() ?? 'audience',
      seatNumber: json['seat_number'] == null
          ? null
          : _asInt(json['seat_number']),
      micMuted: json['mic_muted'] == true || _asInt(json['mic_muted']) == 1,
      participants: (json['participants'] as List? ?? const <dynamic>[])
          .map(
            (item) => RoomAudioParticipantData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

abstract class RoomAudioRepository {
  static RoomAudioRepository instance = LiveRoomAudioRepository();

  Future<RoomAudioSessionData> joinSession(int roomId);

  Future<RoomAudioSessionData> heartbeat(int roomId);

  Future<void> leaveSession(int roomId);

  Future<void> endRoom(int roomId);

  Future<RoomAudioSessionData> fetchToken(int roomId);

  Future<RoomAudioSessionData> updateMicrophone({
    required int roomId,
    required bool muted,
  });

  Future<List<RoomAudioParticipantData>> listParticipants(int roomId);
}

final class LiveRoomAudioRepository implements RoomAudioRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<RoomAudioSessionData> joinSession(int roomId) async {
    final response = await _client.post(
      '/rooms/$roomId/audio/join',
      bearerToken: _authStore.authToken,
    );
    return _mapSession(response);
  }

  @override
  Future<RoomAudioSessionData> heartbeat(int roomId) async {
    final response = await _client.post(
      '/rooms/$roomId/audio/heartbeat',
      bearerToken: _authStore.authToken,
    );
    return _mapSession(response);
  }

  @override
  Future<void> leaveSession(int roomId) async {
    await _client.post(
      '/rooms/$roomId/audio/leave',
      bearerToken: _authStore.authToken,
    );
  }

  @override
  Future<void> endRoom(int roomId) async {
    await _client.post(
      '/rooms/$roomId/audio/end',
      bearerToken: _authStore.authToken,
    );
  }

  @override
  Future<RoomAudioSessionData> fetchToken(int roomId) async {
    final response = await _client.get(
      '/rooms/$roomId/audio/token',
      bearerToken: _authStore.authToken,
    );
    return _mapSession(response);
  }

  @override
  Future<RoomAudioSessionData> updateMicrophone({
    required int roomId,
    required bool muted,
  }) async {
    final response = await _client.post(
      '/rooms/$roomId/audio/microphone',
      body: {'muted': muted},
      bearerToken: _authStore.authToken,
    );
    return _mapSession(response);
  }

  @override
  Future<List<RoomAudioParticipantData>> listParticipants(int roomId) async {
    final response = await _client.get(
      '/rooms/$roomId/audio/participants',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['participants'] as List? ?? const <dynamic>[])
        .map(
          (item) => RoomAudioParticipantData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  RoomAudioSessionData _mapSession(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    return RoomAudioSessionData.fromJson(data);
  }
}

final class FakeRoomAudioRepository implements RoomAudioRepository {
  FakeRoomAudioRepository();

  final List<RoomAudioParticipantData> _participants =
      <RoomAudioParticipantData>[
        const RoomAudioParticipantData(
          id: 1,
          roomId: 1,
          userId: 1,
          userAccount: 'user-1',
          displayName: 'محمد أحمد',
          avatarAsset: 'assets/images/profile_avatar.png',
          role: RoomAudioParticipantRole.host,
          seatNumber: null,
          micMuted: false,
          status: 'joined',
          joinedAt: '2026-04-28 12:00:00',
          lastSeenAt: '2026-04-28 12:00:00',
        ),
        const RoomAudioParticipantData(
          id: 2,
          roomId: 1,
          userId: 2,
          userAccount: 'user-2',
          displayName: 'Mohammed Ahmed',
          avatarAsset: 'assets/images/profile_avatar.png',
          role: RoomAudioParticipantRole.speaker,
          seatNumber: 1,
          micMuted: false,
          status: 'joined',
          joinedAt: '2026-04-28 12:00:00',
          lastSeenAt: '2026-04-28 12:00:00',
        ),
      ];

  @override
  Future<RoomAudioSessionData> joinSession(int roomId) async {
    return _session(roomId: roomId, enabled: false, configured: false);
  }

  @override
  Future<RoomAudioSessionData> heartbeat(int roomId) async {
    return _session(roomId: roomId, enabled: false, configured: false);
  }

  @override
  Future<void> leaveSession(int roomId) async {}

  @override
  Future<void> endRoom(int roomId) async {}

  @override
  Future<RoomAudioSessionData> fetchToken(int roomId) async {
    return _session(roomId: roomId, enabled: false, configured: false);
  }

  @override
  Future<RoomAudioSessionData> updateMicrophone({
    required int roomId,
    required bool muted,
  }) async {
    return _session(
      roomId: roomId,
      enabled: false,
      configured: false,
      micMuted: muted,
    );
  }

  @override
  Future<List<RoomAudioParticipantData>> listParticipants(int roomId) async {
    return _participants
        .where((participant) => participant.roomId == roomId)
        .toList();
  }

  RoomAudioSessionData _session({
    required int roomId,
    required bool enabled,
    required bool configured,
    bool micMuted = false,
  }) {
    return RoomAudioSessionData(
      enabled: enabled,
      configured: configured,
      usesTokens: false,
      appId: '',
      channelName: 'voice-room-$roomId',
      token: '',
      tokenExpiresInSeconds: 3600,
      userAccount: 'user-999',
      role: RoomAudioParticipantRole.listener,
      clientRole: 'audience',
      seatNumber: null,
      micMuted: micMuted,
      participants: _participants
          .where((participant) => participant.roomId == roomId)
          .toList(),
    );
  }
}

RoomAudioParticipantRole _roleFromString(String value) {
  switch (value) {
    case 'host':
      return RoomAudioParticipantRole.host;
    case 'speaker':
      return RoomAudioParticipantRole.speaker;
    default:
      return RoomAudioParticipantRole.listener;
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
