import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class RoomData {
  const RoomData({
    required this.id,
    required this.cardTitle,
    required this.roomTitle,
    required this.subtitle,
    required this.hostName,
    required this.roomCode,
    required this.cardImageAsset,
    required this.metaIconAsset,
    required this.hostAvatarAsset,
    required this.listenerCount,
    required this.micCount,
    required this.backgroundAsset,
    required this.pendingRequestSeatNumbers,
  });

  final int id;
  final String cardTitle;
  final String roomTitle;
  final String subtitle;
  final String hostName;
  final String roomCode;
  final String cardImageAsset;
  final String metaIconAsset;
  final String hostAvatarAsset;
  final int listenerCount;
  final int micCount;
  final String backgroundAsset;
  final List<int> pendingRequestSeatNumbers;

  factory RoomData.fromJson(Map<String, dynamic> json) {
    return RoomData(
      id: _asInt(json['id'], fallback: 1),
      cardTitle: json['card_title']?.toString() ?? '',
      roomTitle: json['room_title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      hostName: json['host_name']?.toString() ?? '',
      roomCode: json['room_code']?.toString() ?? '',
      cardImageAsset: json['card_image_asset']?.toString() ?? '',
      metaIconAsset: json['meta_icon_asset']?.toString() ?? '',
      hostAvatarAsset: json['host_avatar_asset']?.toString() ?? '',
      listenerCount: _asInt(json['listener_count']),
      micCount: _asInt(json['mic_count'], fallback: 9),
      backgroundAsset:
          json['background_asset']?.toString() ??
          'assets/images/room_background.jpg',
      pendingRequestSeatNumbers: (json['pending_request_seat_numbers'] as List?)
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
    String? hostName,
    String? roomCode,
    String? cardImageAsset,
    String? metaIconAsset,
    String? hostAvatarAsset,
    int? listenerCount,
    int? micCount,
    String? backgroundAsset,
    List<int>? pendingRequestSeatNumbers,
  }) {
    return RoomData(
      id: id ?? this.id,
      cardTitle: cardTitle ?? this.cardTitle,
      roomTitle: roomTitle ?? this.roomTitle,
      subtitle: subtitle ?? this.subtitle,
      hostName: hostName ?? this.hostName,
      roomCode: roomCode ?? this.roomCode,
      cardImageAsset: cardImageAsset ?? this.cardImageAsset,
      metaIconAsset: metaIconAsset ?? this.metaIconAsset,
      hostAvatarAsset: hostAvatarAsset ?? this.hostAvatarAsset,
      listenerCount: listenerCount ?? this.listenerCount,
      micCount: micCount ?? this.micCount,
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
    hostName: 'محمد أحمد',
    roomCode: '1512345412',
    cardImageAsset: 'assets/images/home_room_service.png',
    metaIconAsset: 'assets/images/home_pin_icon.png',
    hostAvatarAsset: 'assets/images/profile_avatar.png',
    listenerCount: 30,
    micCount: 9,
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

  Future<List<RoomData>> listRooms();

  Future<RoomData> getRoom(int roomId);

  Future<RoomData> updateMicCount({
    required int roomId,
    required int micCount,
  });

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
  Future<List<RoomData>> listRooms() async {
    final response = await _client.get(
      '/rooms',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['rooms'] as List? ?? const <dynamic>[])
        .map((item) => RoomData.fromJson(Map<String, dynamic>.from(item as Map)))
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
    final response = await _client.get(
      path,
      bearerToken: _authStore.authToken,
    );
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
  Future<List<RoomData>> listRooms() async {
    return _rooms.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<RoomData> getRoom(int roomId) async {
    final room = _rooms[roomId] ?? RoomData.fallback;
    final pendingSeats = _requests
        .where((request) => request.roomId == roomId && request.status == 'pending')
        .map((request) => request.seatNumber)
        .toSet()
        .toList()
      ..sort();
    return room.copyWith(pendingRequestSeatNumbers: pendingSeats);
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
