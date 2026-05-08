import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class RoomImageDraft {
  const RoomImageDraft({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  Map<String, dynamic> toJson() {
    return {
      'filename': fileName,
      'mime_type': mimeType,
      'content_base64': base64Encode(bytes),
    };
  }
}

class RoomData {
  const RoomData({
    required this.id,
    required this.cardTitle,
    required this.roomTitle,
    required this.subtitle,
    required this.roomType,
    required this.sloganText,
    required this.countryLabel,
    required this.hostName,
    required this.hostUserId,
    required this.creatorUserId,
    required this.roomCode,
    required this.cardImageAsset,
    required this.metaIconAsset,
    required this.hostAvatarAsset,
    required this.listenerCount,
    required this.micCount,
    required this.audioEnabled,
    required this.agoraChannelName,
    required this.backgroundAsset,
    required this.pendingRequestSeatNumbers,
  });

  final int id;
  final String cardTitle;
  final String roomTitle;
  final String subtitle;
  final String roomType;
  final String sloganText;
  final String countryLabel;
  final String hostName;
  final int? hostUserId;
  final int? creatorUserId;
  final String roomCode;
  final String cardImageAsset;
  final String metaIconAsset;
  final String hostAvatarAsset;
  final int listenerCount;
  final int micCount;
  final bool audioEnabled;
  final String agoraChannelName;
  final String backgroundAsset;
  final List<int> pendingRequestSeatNumbers;

  factory RoomData.fromJson(Map<String, dynamic> json) {
    return RoomData(
      id: _asInt(json['id'], fallback: 1),
      cardTitle: json['card_title']?.toString() ?? '',
      roomTitle: json['room_title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      roomType: json['room_type']?.toString() ?? 'غناء',
      sloganText: json['slogan_text']?.toString() ?? '',
      countryLabel: json['country_label']?.toString() ?? 'مصر',
      hostName: json['host_name']?.toString() ?? '',
      hostUserId: json['host_user_id'] == null
          ? null
          : _asInt(json['host_user_id']),
      creatorUserId: json['creator_user_id'] == null
          ? null
          : _asInt(json['creator_user_id']),
      roomCode: json['room_code']?.toString() ?? '',
      cardImageAsset: json['card_image_asset']?.toString() ?? '',
      metaIconAsset: json['meta_icon_asset']?.toString() ?? '',
      hostAvatarAsset: json['host_avatar_asset']?.toString() ?? '',
      listenerCount: _asInt(json['listener_count']),
      micCount: _asInt(json['mic_count'], fallback: 9),
      audioEnabled:
          json['audio_enabled'] == true || _asInt(json['audio_enabled']) == 1,
      agoraChannelName: json['agora_channel_name']?.toString() ?? '',
      backgroundAsset:
          json['background_asset']?.toString() ??
          'assets/images/room_background.jpg',
      pendingRequestSeatNumbers:
          (json['pending_request_seat_numbers'] as List?)
              ?.map((value) => _asInt(value))
              .toList() ??
          const <int>[],
    );
  }

  RoomData copyWith({
    int? id,
    String? cardTitle,
    String? roomTitle,
    String? subtitle,
    String? roomType,
    String? sloganText,
    String? countryLabel,
    String? hostName,
    int? hostUserId,
    int? creatorUserId,
    String? roomCode,
    String? cardImageAsset,
    String? metaIconAsset,
    String? hostAvatarAsset,
    int? listenerCount,
    int? micCount,
    bool? audioEnabled,
    String? agoraChannelName,
    String? backgroundAsset,
    List<int>? pendingRequestSeatNumbers,
  }) {
    return RoomData(
      id: id ?? this.id,
      cardTitle: cardTitle ?? this.cardTitle,
      roomTitle: roomTitle ?? this.roomTitle,
      subtitle: subtitle ?? this.subtitle,
      roomType: roomType ?? this.roomType,
      sloganText: sloganText ?? this.sloganText,
      countryLabel: countryLabel ?? this.countryLabel,
      hostName: hostName ?? this.hostName,
      hostUserId: hostUserId ?? this.hostUserId,
      creatorUserId: creatorUserId ?? this.creatorUserId,
      roomCode: roomCode ?? this.roomCode,
      cardImageAsset: cardImageAsset ?? this.cardImageAsset,
      metaIconAsset: metaIconAsset ?? this.metaIconAsset,
      hostAvatarAsset: hostAvatarAsset ?? this.hostAvatarAsset,
      listenerCount: listenerCount ?? this.listenerCount,
      micCount: micCount ?? this.micCount,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      agoraChannelName: agoraChannelName ?? this.agoraChannelName,
      backgroundAsset: backgroundAsset ?? this.backgroundAsset,
      pendingRequestSeatNumbers:
          pendingRequestSeatNumbers ?? this.pendingRequestSeatNumbers,
    );
  }

  static const RoomData fallback = RoomData(
    id: 1,
    cardTitle: 'الشكاوي والاقتراحات',
    roomTitle: 'أريد أن أسمع صوتك',
    subtitle: 'اهلا وسهلا بكم في روم مصر ام الدنيا',
    roomType: 'دردشة',
    sloganText: 'ابحث عن شخص يمكنه الدردشه معي هالحين',
    countryLabel: 'مصر',
    hostName: 'محمد أحمد',
    hostUserId: 1,
    creatorUserId: 1,
    roomCode: '1512345412',
    cardImageAsset: 'assets/images/home_room_service.png',
    metaIconAsset: 'assets/images/home_pin_icon.png',
    hostAvatarAsset: 'assets/images/profile_avatar.png',
    listenerCount: 30,
    micCount: 9,
    audioEnabled: true,
    agoraChannelName: 'voice-room-1512345412',
    backgroundAsset: 'assets/images/room_background.jpg',
    pendingRequestSeatNumbers: <int>[],
  );
}

class RoomSeatRequestData {
  const RoomSeatRequestData({
    required this.id,
    required this.roomId,
    required this.seatNumber,
    required this.requesterName,
    required this.requesterAvatarAsset,
    required this.status,
  });

  final int id;
  final int roomId;
  final int seatNumber;
  final String requesterName;
  final String requesterAvatarAsset;
  final String status;

  factory RoomSeatRequestData.fromJson(Map<String, dynamic> json) {
    return RoomSeatRequestData(
      id: _asInt(json['id']),
      roomId: _asInt(json['room_id'], fallback: 1),
      seatNumber: _asInt(json['seat_number'], fallback: 1),
      requesterName: json['requester_name']?.toString() ?? 'Mohammed Ahmed',
      requesterAvatarAsset:
          json['requester_avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

abstract class RoomRepository {
  static RoomRepository instance = LiveRoomRepository();

  Future<List<RoomData>> listRooms({String scope = 'newest'});

  Future<RoomData> getRoom(int roomId);

  Future<RoomData> createRoom({
    required String roomName,
    required String roomType,
    required String sloganText,
    required String countryLabel,
    required String cardImageAsset,
    RoomImageDraft? cardImageDraft,
  });

  Future<RoomData> updateMicCount({required int roomId, required int micCount});

  Future<RoomSeatRequestData> createSeatRequest({
    required int roomId,
    required int seatNumber,
  });

  Future<List<RoomSeatRequestData>> listSeatRequests({
    required int roomId,
    int? seatNumber,
  });
}

final class LiveRoomRepository implements RoomRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<List<RoomData>> listRooms({String scope = 'newest'}) async {
    final response = await _client.get(
      '/rooms?scope=$scope',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['rooms'] as List? ?? const <dynamic>[])
        .map(
          (item) => RoomData.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<RoomData> getRoom(int roomId) async {
    final response = await _client.get(
      '/rooms/$roomId',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return RoomData.fromJson(Map<String, dynamic>.from(data['room'] as Map));
  }

  @override
  Future<RoomData> createRoom({
    required String roomName,
    required String roomType,
    required String sloganText,
    required String countryLabel,
    required String cardImageAsset,
    RoomImageDraft? cardImageDraft,
  }) async {
    final response = await _client.post(
      '/rooms',
      body: {
        'room_name': roomName,
        'room_type': roomType,
        'slogan_text': sloganText,
        'country_label': countryLabel,
        'card_image_asset': cardImageAsset,
        'card_image_upload': cardImageDraft?.toJson(),
      },
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return RoomData.fromJson(Map<String, dynamic>.from(data['room'] as Map));
  }

  @override
  Future<RoomData> updateMicCount({
    required int roomId,
    required int micCount,
  }) async {
    final response = await _client.post(
      '/rooms/$roomId/mic-count',
      body: {'mic_count': micCount},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return RoomData.fromJson(Map<String, dynamic>.from(data['room'] as Map));
  }

  @override
  Future<RoomSeatRequestData> createSeatRequest({
    required int roomId,
    required int seatNumber,
  }) async {
    final response = await _client.post(
      '/rooms/$roomId/seat-requests',
      body: {'seat_number': seatNumber},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return RoomSeatRequestData.fromJson(
      Map<String, dynamic>.from(data['request'] as Map),
    );
  }

  @override
  Future<List<RoomSeatRequestData>> listSeatRequests({
    required int roomId,
    int? seatNumber,
  }) async {
    final path = seatNumber == null
        ? '/rooms/$roomId/seat-requests'
        : '/rooms/$roomId/seat-requests?seat_number=$seatNumber';
    final response = await _client.get(path, bearerToken: _authStore.authToken);
    final data = response['data'] as Map<String, dynamic>;
    return (data['requests'] as List? ?? const <dynamic>[])
        .map(
          (item) => RoomSeatRequestData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}

final class FakeRoomRepository implements RoomRepository {
  FakeRoomRepository() {
    _seed();
  }

  final Map<int, RoomData> _rooms = <int, RoomData>{};
  final List<RoomSeatRequestData> _requests = <RoomSeatRequestData>[];
  int _nextRequestId = 1;
  int _nextRoomId = 5;

  void _seed() {
    if (_rooms.isNotEmpty) {
      return;
    }

    final fallback = RoomData.fallback;
    _rooms[fallback.id] = fallback;
    _rooms[2] = fallback.copyWith(
      id: 2,
      cardTitle: 'خدمة العملاء',
      roomTitle: 'غرفة الدعم المباشر',
      roomCode: '1512345413',
    );
    _rooms[3] = fallback.copyWith(
      id: 3,
      cardTitle: 'وكالة ولاد الملوك',
      roomTitle: 'وكالة ولاد الملوك',
      roomCode: '1512345414',
      cardImageAsset: 'assets/images/home_room_1.png',
      metaIconAsset: 'assets/images/home_egypt_flag.png',
    );
    _rooms[4] = fallback.copyWith(
      id: 4,
      cardTitle: 'وكالة ولاد الملوك',
      roomTitle: 'وكالة ولاد الملوك',
      roomCode: '1512345415',
      cardImageAsset: 'assets/images/home_room_2.png',
      metaIconAsset: 'assets/images/home_egypt_flag.png',
    );
  }

  @override
  Future<List<RoomData>> listRooms({String scope = 'newest'}) async {
    final rooms = _rooms.values.toList();
    if (scope == 'friends') {
      rooms.removeWhere((room) => room.id.isOdd);
    }
    if (scope == 'hashtag') {
      rooms.sort((a, b) {
        final leftScore =
            (a.listenerCount * 10) + a.roomType.length + a.countryLabel.length;
        final rightScore =
            (b.listenerCount * 10) + b.roomType.length + b.countryLabel.length;
        return rightScore.compareTo(leftScore);
      });
      return rooms;
    }

    return rooms..sort((a, b) => b.id.compareTo(a.id));
  }

  @override
  Future<RoomData> getRoom(int roomId) async {
    final room = _rooms[roomId] ?? RoomData.fallback;
    final pendingSeats =
        _requests
            .where(
              (request) =>
                  request.roomId == roomId && request.status == 'pending',
            )
            .map((request) => request.seatNumber)
            .toSet()
            .toList()
          ..sort();
    return room.copyWith(pendingRequestSeatNumbers: pendingSeats);
  }

  @override
  Future<RoomData> createRoom({
    required String roomName,
    required String roomType,
    required String sloganText,
    required String countryLabel,
    required String cardImageAsset,
    RoomImageDraft? cardImageDraft,
  }) async {
    final user = AuthFlowStore.instance.currentUser;
    final id = _nextRoomId++;
    final room = RoomData.fallback.copyWith(
      id: id,
      cardTitle: roomName,
      roomTitle: roomName,
      subtitle: sloganText.isEmpty ? 'اهلا وسهلا بكم في غرفتي' : sloganText,
      roomType: roomType,
      sloganText: sloganText,
      countryLabel: countryLabel,
      hostName:
          user?['nickname']?.toString() ??
          user?['email']?.toString() ??
          'Hallo Party User',
      hostUserId: _asNullableInt(user?['id']),
      creatorUserId: _asNullableInt(user?['id']),
      roomCode: (1512345400 + id).toString(),
      cardImageAsset: cardImageAsset,
      metaIconAsset: countryLabel == 'مصر'
          ? 'assets/images/home_egypt_flag.png'
          : 'assets/images/profile_country_flag.png',
      hostAvatarAsset:
          user?['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      listenerCount: 1,
      micCount: 9,
      agoraChannelName: 'voice-room-${1512345400 + id}',
      pendingRequestSeatNumbers: const <int>[],
    );
    _rooms[id] = room;
    return room;
  }

  @override
  Future<RoomData> updateMicCount({
    required int roomId,
    required int micCount,
  }) async {
    final room = _rooms[roomId] ?? RoomData.fallback;
    final updated = room.copyWith(micCount: micCount);
    _rooms[roomId] = updated;
    return updated;
  }

  @override
  Future<RoomSeatRequestData> createSeatRequest({
    required int roomId,
    required int seatNumber,
  }) async {
    final existing = _requests.where(
      (request) =>
          request.roomId == roomId &&
          request.seatNumber == seatNumber &&
          request.status == 'pending',
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final requesterName =
        AuthFlowStore.instance.currentUser?['nickname']?.toString() ??
        'Mohammed Ahmed';
    final request = RoomSeatRequestData(
      id: _nextRequestId++,
      roomId: roomId,
      seatNumber: seatNumber,
      requesterName: requesterName,
      requesterAvatarAsset: 'assets/images/profile_avatar.png',
      status: 'pending',
    );
    _requests.add(request);
    return request;
  }

  @override
  Future<List<RoomSeatRequestData>> listSeatRequests({
    required int roomId,
    int? seatNumber,
  }) async {
    return _requests
        .where(
          (request) =>
              request.roomId == roomId &&
              request.status == 'pending' &&
              (seatNumber == null || request.seatNumber == seatNumber),
        )
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  return _asInt(value);
}
