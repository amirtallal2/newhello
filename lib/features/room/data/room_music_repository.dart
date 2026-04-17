import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_flow_store.dart';

enum RoomMusicSourceType { friends, whatsapp }

extension RoomMusicSourceTypeX on RoomMusicSourceType {
  String get apiValue => switch (this) {
    RoomMusicSourceType.friends => 'friends',
    RoomMusicSourceType.whatsapp => 'whatsapp',
  };

  String get label => switch (this) {
    RoomMusicSourceType.friends => 'الاصدقاء',
    RoomMusicSourceType.whatsapp => 'واتساب',
  };

  static RoomMusicSourceType fromApi(String value) {
    return value == 'whatsapp'
        ? RoomMusicSourceType.whatsapp
        : RoomMusicSourceType.friends;
  }
}

class RoomMusicTrackData {
  const RoomMusicTrackData({
    required this.id,
    required this.title,
    required this.artistName,
    required this.sourceType,
    required this.coverAsset,
    required this.durationSeconds,
    required this.durationLabel,
  });

  final int id;
  final String title;
  final String artistName;
  final RoomMusicSourceType sourceType;
  final String coverAsset;
  final int durationSeconds;
  final String durationLabel;

  factory RoomMusicTrackData.fromJson(Map<String, dynamic> json) {
    return RoomMusicTrackData(
      id: _musicAsInt(json['id'], fallback: 1),
      title: json['title']?.toString() ?? 'Friends Beat 01',
      artistName: json['artist_name']?.toString() ?? 'DJ Nona',
      sourceType: RoomMusicSourceTypeX.fromApi(
        json['source_type']?.toString() ?? 'friends',
      ),
      coverAsset:
          json['cover_asset']?.toString() ??
          'assets/images/profile_store_friend_nona_avatar.png',
      durationSeconds: _musicAsInt(json['duration_seconds'], fallback: 180),
      durationLabel: json['duration_label']?.toString() ?? '3:00',
    );
  }
}

class RoomMusicPlaylistEntryData {
  const RoomMusicPlaylistEntryData({
    required this.id,
    required this.roomId,
    required this.trackId,
    required this.title,
    required this.artistName,
    required this.sourceType,
    required this.coverAsset,
    required this.durationSeconds,
    required this.durationLabel,
    required this.addedByName,
  });

  final int id;
  final int roomId;
  final int trackId;
  final String title;
  final String artistName;
  final RoomMusicSourceType sourceType;
  final String coverAsset;
  final int durationSeconds;
  final String durationLabel;
  final String addedByName;

  factory RoomMusicPlaylistEntryData.fromJson(Map<String, dynamic> json) {
    return RoomMusicPlaylistEntryData(
      id: _musicAsInt(json['id'], fallback: 1),
      roomId: _musicAsInt(json['room_id'], fallback: 1),
      trackId: _musicAsInt(json['track_id'], fallback: 1),
      title: json['title']?.toString() ?? 'Friends Beat 01',
      artistName: json['artist_name']?.toString() ?? 'DJ Nona',
      sourceType: RoomMusicSourceTypeX.fromApi(
        json['source_type']?.toString() ?? 'friends',
      ),
      coverAsset:
          json['cover_asset']?.toString() ??
          'assets/images/profile_store_friend_nona_avatar.png',
      durationSeconds: _musicAsInt(json['duration_seconds'], fallback: 180),
      durationLabel: json['duration_label']?.toString() ?? '3:00',
      addedByName: json['added_by_name']?.toString() ?? 'Mohammed Ahmed',
    );
  }
}

class RoomMusicPlaylistData {
  const RoomMusicPlaylistData({required this.roomId, required this.entries});

  final int roomId;
  final List<RoomMusicPlaylistEntryData> entries;
}

abstract class RoomMusicRepository {
  static RoomMusicRepository instance = LiveRoomMusicRepository();

  Future<RoomMusicPlaylistData> loadPlaylist({required int roomId});

  Future<RoomMusicPlaylistData> addFirstTrackFromSource({
    required int roomId,
    required RoomMusicSourceType sourceType,
  });

  Future<RoomMusicPlaylistData> removeTrack({
    required int roomId,
    required int playlistEntryId,
  });
}

final class LiveRoomMusicRepository implements RoomMusicRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<RoomMusicPlaylistData> loadPlaylist({required int roomId}) async {
    final response = await _client.get(
      '/rooms/$roomId/music/playlist',
      bearerToken: _authStore.authToken,
    );
    return _playlistFromResponse(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<RoomMusicPlaylistData> addFirstTrackFromSource({
    required int roomId,
    required RoomMusicSourceType sourceType,
  }) async {
    final catalogResponse = await _client.get(
      '/music/catalog?source=${sourceType.apiValue}',
      bearerToken: _authStore.authToken,
    );
    final catalogData = catalogResponse['data'] as Map<String, dynamic>;
    final tracks = (catalogData['tracks'] as List? ?? const <dynamic>[])
        .map(
          (item) => RoomMusicTrackData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    if (tracks.isEmpty) {
      throw ApiException('لا توجد موسيقى متاحة لهذا المصدر حاليا.');
    }

    final response = await _client.post(
      '/rooms/$roomId/music/playlist',
      body: {'track_id': tracks.first.id},
      bearerToken: _authStore.authToken,
    );
    return _playlistFromResponse(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<RoomMusicPlaylistData> removeTrack({
    required int roomId,
    required int playlistEntryId,
  }) async {
    final response = await _client.post(
      '/rooms/$roomId/music/playlist/$playlistEntryId/remove',
      bearerToken: _authStore.authToken,
    );
    return _playlistFromResponse(response['data'] as Map<String, dynamic>);
  }

  RoomMusicPlaylistData _playlistFromResponse(Map<String, dynamic> data) {
    return RoomMusicPlaylistData(
      roomId: _musicAsInt(data['room_id'], fallback: 1),
      entries: (data['entries'] as List? ?? const <dynamic>[])
          .map(
            (item) => RoomMusicPlaylistEntryData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

final class FakeRoomMusicRepository implements RoomMusicRepository {
  final Map<int, List<RoomMusicTrackData>> _catalogByRoom =
      <int, List<RoomMusicTrackData>>{};
  final Map<int, List<RoomMusicPlaylistEntryData>> _playlistByRoom =
      <int, List<RoomMusicPlaylistEntryData>>{};
  final Map<RoomMusicSourceType, int> _nextTrackIndexBySource =
      <RoomMusicSourceType, int>{
        RoomMusicSourceType.friends: 0,
        RoomMusicSourceType.whatsapp: 0,
      };
  int _nextPlaylistEntryId = 1;

  FakeRoomMusicRepository() {
    _seed();
  }

  void _seed() {
    if (_catalogByRoom.isNotEmpty) {
      return;
    }

    _catalogByRoom[1] = const <RoomMusicTrackData>[
      RoomMusicTrackData(
        id: 1,
        title: 'Friends Beat 01',
        artistName: 'DJ Nona',
        sourceType: RoomMusicSourceType.friends,
        coverAsset: 'assets/images/profile_store_friend_nona_avatar.png',
        durationSeconds: 192,
        durationLabel: '3:12',
      ),
      RoomMusicTrackData(
        id: 2,
        title: 'Friends Beat 02',
        artistName: 'Mohammed Ahmed',
        sourceType: RoomMusicSourceType.friends,
        coverAsset: 'assets/images/profile_avatar.png',
        durationSeconds: 205,
        durationLabel: '3:25',
      ),
      RoomMusicTrackData(
        id: 3,
        title: 'WhatsApp Voice Mix',
        artistName: 'Support Team',
        sourceType: RoomMusicSourceType.whatsapp,
        coverAsset: 'assets/images/home_room_service.png',
        durationSeconds: 170,
        durationLabel: '2:50',
      ),
      RoomMusicTrackData(
        id: 4,
        title: 'WhatsApp Party Loop',
        artistName: 'Ahmed Ali',
        sourceType: RoomMusicSourceType.whatsapp,
        coverAsset: 'assets/images/home_room_1.png',
        durationSeconds: 214,
        durationLabel: '3:34',
      ),
    ];
    _playlistByRoom[1] = <RoomMusicPlaylistEntryData>[];
  }

  @override
  Future<RoomMusicPlaylistData> loadPlaylist({required int roomId}) async {
    return RoomMusicPlaylistData(
      roomId: roomId,
      entries: List<RoomMusicPlaylistEntryData>.from(
        _playlistByRoom[roomId] ?? const <RoomMusicPlaylistEntryData>[],
      ),
    );
  }

  @override
  Future<RoomMusicPlaylistData> addFirstTrackFromSource({
    required int roomId,
    required RoomMusicSourceType sourceType,
  }) async {
    final catalog = (_catalogByRoom[roomId] ?? const <RoomMusicTrackData>[])
        .where((track) => track.sourceType == sourceType)
        .toList();
    if (catalog.isEmpty) {
      throw ApiException('لا توجد موسيقى متاحة لهذا المصدر حاليا.');
    }

    final currentIndex = _nextTrackIndexBySource[sourceType] ?? 0;
    final track = catalog[currentIndex % catalog.length];
    _nextTrackIndexBySource[sourceType] = currentIndex + 1;

    final entries = List<RoomMusicPlaylistEntryData>.from(
      _playlistByRoom[roomId] ?? <RoomMusicPlaylistEntryData>[],
    );
    entries.add(
      RoomMusicPlaylistEntryData(
        id: _nextPlaylistEntryId++,
        roomId: roomId,
        trackId: track.id,
        title: track.title,
        artistName: track.artistName,
        sourceType: track.sourceType,
        coverAsset: track.coverAsset,
        durationSeconds: track.durationSeconds,
        durationLabel: track.durationLabel,
        addedByName:
            AuthFlowStore.instance.currentUser?['nickname']?.toString() ??
            'Mohammed Ahmed',
      ),
    );
    _playlistByRoom[roomId] = entries;

    return loadPlaylist(roomId: roomId);
  }

  @override
  Future<RoomMusicPlaylistData> removeTrack({
    required int roomId,
    required int playlistEntryId,
  }) async {
    final entries = List<RoomMusicPlaylistEntryData>.from(
      _playlistByRoom[roomId] ?? <RoomMusicPlaylistEntryData>[],
    )..removeWhere((entry) => entry.id == playlistEntryId);
    _playlistByRoom[roomId] = entries;

    return loadPlaylist(roomId: roomId);
  }
}

int _musicAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
