import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class RoomGameCatalogData {
  const RoomGameCatalogData({required this.roomId, required this.games});

  final int roomId;
  final List<RoomGameItemData> games;
}

class RoomGameItemData {
  const RoomGameItemData({
    required this.id,
    required this.gameKey,
    required this.name,
    required this.categoryKey,
    required this.categoryLabel,
    required this.iconAsset,
    required this.descriptionText,
    required this.minPlayers,
    required this.maxPlayers,
    required this.activeSession,
  });

  final int id;
  final String gameKey;
  final String name;
  final String categoryKey;
  final String categoryLabel;
  final String iconAsset;
  final String descriptionText;
  final int minPlayers;
  final int maxPlayers;
  final RoomGameSessionSummaryData? activeSession;

  factory RoomGameItemData.fromJson(Map<String, dynamic> json) {
    return RoomGameItemData(
      id: _gameAsInt(json['id'], fallback: 1),
      gameKey: json['game_key']?.toString() ?? 'wheel_of_fortune',
      name: json['name']?.toString() ?? 'عجلة الحظ',
      categoryKey: json['category_key']?.toString() ?? 'luck',
      categoryLabel: json['category_label']?.toString() ?? 'العاب الحظ',
      iconAsset:
          json['icon_asset']?.toString() ??
          'assets/images/room_game_wheel_icon.png',
      descriptionText:
          json['description_text']?.toString() ?? 'جلسة ترفيهية داخل الغرفة.',
      minPlayers: _gameAsInt(json['min_players'], fallback: 1),
      maxPlayers: _gameAsInt(json['max_players'], fallback: 4),
      activeSession: json['active_session'] is Map
          ? RoomGameSessionSummaryData.fromJson(
              Map<String, dynamic>.from(json['active_session'] as Map),
            )
          : null,
    );
  }
}

class RoomGameSessionSummaryData {
  const RoomGameSessionSummaryData({
    required this.id,
    required this.roomId,
    required this.gameId,
    required this.playerCount,
    required this.maxPlayers,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
  });

  final int id;
  final int roomId;
  final int gameId;
  final int playerCount;
  final int maxPlayers;
  final String status;
  final String statusLabel;
  final String createdAt;

  factory RoomGameSessionSummaryData.fromJson(Map<String, dynamic> json) {
    return RoomGameSessionSummaryData(
      id: _gameAsInt(json['id'], fallback: 1),
      roomId: _gameAsInt(json['room_id'], fallback: 1),
      gameId: _gameAsInt(json['game_id'], fallback: 1),
      playerCount: _gameAsInt(json['player_count'], fallback: 0),
      maxPlayers: _gameAsInt(json['max_players'], fallback: 4),
      status: json['status']?.toString() ?? 'active',
      statusLabel: json['status_label']?.toString() ?? 'نشطة الآن',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class RoomGamePlayerData {
  const RoomGamePlayerData({
    required this.id,
    required this.userId,
    required this.playerName,
    required this.seatNumber,
    required this.joinedAt,
  });

  final int id;
  final int userId;
  final String playerName;
  final int seatNumber;
  final String joinedAt;

  factory RoomGamePlayerData.fromJson(Map<String, dynamic> json) {
    return RoomGamePlayerData(
      id: _gameAsInt(json['id'], fallback: 1),
      userId: _gameAsInt(json['user_id'], fallback: 0),
      playerName: json['player_name']?.toString() ?? 'لاعب',
      seatNumber: _gameAsInt(json['seat_number'], fallback: 1),
      joinedAt: json['joined_at']?.toString() ?? '',
    );
  }
}

class RoomGameSessionData {
  const RoomGameSessionData({
    required this.id,
    required this.roomId,
    required this.gameId,
    required this.playerCount,
    required this.maxPlayers,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.hostName,
    required this.players,
    required this.isJoined,
  });

  final int id;
  final int roomId;
  final int gameId;
  final int playerCount;
  final int maxPlayers;
  final String status;
  final String statusLabel;
  final String createdAt;
  final String hostName;
  final List<RoomGamePlayerData> players;
  final bool isJoined;

  factory RoomGameSessionData.fromJson(Map<String, dynamic> json) {
    return RoomGameSessionData(
      id: _gameAsInt(json['id'], fallback: 1),
      roomId: _gameAsInt(json['room_id'], fallback: 1),
      gameId: _gameAsInt(json['game_id'], fallback: 1),
      playerCount: _gameAsInt(json['player_count'], fallback: 0),
      maxPlayers: _gameAsInt(json['max_players'], fallback: 4),
      status: json['status']?.toString() ?? 'active',
      statusLabel: json['status_label']?.toString() ?? 'نشطة الآن',
      createdAt: json['created_at']?.toString() ?? '',
      hostName: json['host_name']?.toString() ?? 'المضيف',
      players: (json['players'] as List? ?? const <dynamic>[])
          .map(
            (item) => RoomGamePlayerData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      isJoined: json['is_joined'] == true,
    );
  }
}

class RoomGameLobbyData {
  const RoomGameLobbyData({
    required this.roomId,
    required this.game,
    required this.activeSession,
  });

  final int roomId;
  final RoomGameItemData game;
  final RoomGameSessionData? activeSession;

  factory RoomGameLobbyData.fromJson(Map<String, dynamic> json) {
    return RoomGameLobbyData(
      roomId: _gameAsInt(json['room_id'], fallback: 1),
      game: RoomGameItemData.fromJson(
        Map<String, dynamic>.from((json['game'] as Map?) ?? const <String, dynamic>{}),
      ),
      activeSession: json['active_session'] is Map
          ? RoomGameSessionData.fromJson(
              Map<String, dynamic>.from(json['active_session'] as Map),
            )
          : null,
    );
  }
}

abstract class RoomGameRepository {
  static RoomGameRepository instance = LiveRoomGameRepository();

  Future<RoomGameCatalogData> loadCatalog({required int roomId});

  Future<RoomGameLobbyData> loadLobby({
    required int roomId,
    required int gameId,
  });

  Future<RoomGameLobbyData> joinGame({
    required int roomId,
    required int gameId,
  });

  Future<RoomGameLobbyData> leaveSession({
    required int roomId,
    required int sessionId,
  });
}

final class LiveRoomGameRepository implements RoomGameRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<RoomGameCatalogData> loadCatalog({required int roomId}) async {
    final response = await _client.get(
      '/rooms/$roomId/games/catalog',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return RoomGameCatalogData(
      roomId: _gameAsInt(data['room_id'], fallback: roomId),
      games: (data['games'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                RoomGameItemData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<RoomGameLobbyData> loadLobby({
    required int roomId,
    required int gameId,
  }) async {
    final response = await _client.get(
      '/rooms/$roomId/games/$gameId',
      bearerToken: _authStore.authToken,
    );
    return RoomGameLobbyData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<RoomGameLobbyData> joinGame({
    required int roomId,
    required int gameId,
  }) async {
    final response = await _client.post(
      '/rooms/$roomId/games/$gameId/join',
      bearerToken: _authStore.authToken,
    );
    return RoomGameLobbyData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<RoomGameLobbyData> leaveSession({
    required int roomId,
    required int sessionId,
  }) async {
    final response = await _client.post(
      '/rooms/$roomId/games/sessions/$sessionId/leave',
      bearerToken: _authStore.authToken,
    );
    return RoomGameLobbyData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

final class FakeRoomGameRepository implements RoomGameRepository {
  final Map<int, List<RoomGameItemData>> _catalogByRoom = <int, List<RoomGameItemData>>{};
  final Map<String, RoomGameSessionData> _sessionByKey =
      <String, RoomGameSessionData>{};
  int _nextSessionId = 1;
  int _nextPlayerId = 10;

  FakeRoomGameRepository() {
    _seed();
  }

  void _seed() {
    _catalogByRoom[1] = const <RoomGameItemData>[
      RoomGameItemData(
        id: 1,
        gameKey: 'wheel_of_fortune',
        name: 'عجلة الحظ',
        categoryKey: 'luck',
        categoryLabel: 'العاب الحظ',
        iconAsset: 'assets/images/room_game_wheel_icon.png',
        descriptionText: 'لعبة سريعة داخل الغرفة لاختيار الفائز بالحظ بين الأعضاء.',
        minPlayers: 1,
        maxPlayers: 8,
        activeSession: null,
      ),
      RoomGameItemData(
        id: 2,
        gameKey: 'ludo',
        name: 'لودو',
        categoryKey: 'board',
        categoryLabel: 'العاب اللوح',
        iconAsset: 'assets/images/room_game_ludo_icon.png',
        descriptionText: 'جلسة لودو جماعية خفيفة بين أعضاء الغرفة.',
        minPlayers: 2,
        maxPlayers: 4,
        activeSession: null,
      ),
      RoomGameItemData(
        id: 3,
        gameKey: 'domino',
        name: 'دومينو',
        categoryKey: 'board',
        categoryLabel: 'العاب اللوح',
        iconAsset: 'assets/images/room_game_domino_icon.png',
        descriptionText: 'لعبة دومينو داخل الغرفة مع إمكانية انضمام عدة لاعبين.',
        minPlayers: 2,
        maxPlayers: 4,
        activeSession: null,
      ),
    ];
  }

  @override
  Future<RoomGameCatalogData> loadCatalog({required int roomId}) async {
    final games = (_catalogByRoom[roomId] ?? const <RoomGameItemData>[])
        .map((game) {
          final session = _sessionByKey[_catalogKey(roomId, game.id)];
          return RoomGameItemData(
            id: game.id,
            gameKey: game.gameKey,
            name: game.name,
            categoryKey: game.categoryKey,
            categoryLabel: game.categoryLabel,
            iconAsset: game.iconAsset,
            descriptionText: game.descriptionText,
            minPlayers: game.minPlayers,
            maxPlayers: game.maxPlayers,
            activeSession: session == null
                ? null
                : RoomGameSessionSummaryData(
                    id: session.id,
                    roomId: session.roomId,
                    gameId: session.gameId,
                    playerCount: session.playerCount,
                    maxPlayers: session.maxPlayers,
                    status: session.status,
                    statusLabel: session.statusLabel,
                    createdAt: session.createdAt,
                  ),
          );
        })
        .toList();

    return RoomGameCatalogData(roomId: roomId, games: games);
  }

  @override
  Future<RoomGameLobbyData> loadLobby({
    required int roomId,
    required int gameId,
  }) async {
    final game = _gameFor(roomId, gameId);
    return RoomGameLobbyData(
      roomId: roomId,
      game: game,
      activeSession: _sessionByKey[_catalogKey(roomId, gameId)],
    );
  }

  @override
  Future<RoomGameLobbyData> joinGame({
    required int roomId,
    required int gameId,
  }) async {
    final game = _gameFor(roomId, gameId);
    final key = _catalogKey(roomId, gameId);
    final existing = _sessionByKey[key];

    if (existing == null) {
      _sessionByKey[key] = RoomGameSessionData(
        id: _nextSessionId++,
        roomId: roomId,
        gameId: gameId,
        playerCount: 1,
        maxPlayers: game.maxPlayers,
        status: 'active',
        statusLabel: 'نشطة الآن',
        createdAt: DateTime.now().toIso8601String(),
        hostName: 'المستخدم الحالي',
        players: <RoomGamePlayerData>[
          RoomGamePlayerData(
            id: _nextPlayerId++,
            userId: 1,
            playerName: 'المستخدم الحالي',
            seatNumber: 1,
            joinedAt: DateTime.now().toIso8601String(),
          ),
        ],
        isJoined: true,
      );
    } else if (!existing.isJoined && existing.playerCount < existing.maxPlayers) {
      final players = List<RoomGamePlayerData>.from(existing.players)
        ..add(
          RoomGamePlayerData(
            id: _nextPlayerId++,
            userId: 1,
            playerName: 'المستخدم الحالي',
            seatNumber: existing.players.length + 1,
            joinedAt: DateTime.now().toIso8601String(),
          ),
        );
      _sessionByKey[key] = RoomGameSessionData(
        id: existing.id,
        roomId: existing.roomId,
        gameId: existing.gameId,
        playerCount: players.length,
        maxPlayers: existing.maxPlayers,
        status: existing.status,
        statusLabel: existing.statusLabel,
        createdAt: existing.createdAt,
        hostName: existing.hostName,
        players: players,
        isJoined: true,
      );
    }

    return loadLobby(roomId: roomId, gameId: gameId);
  }

  @override
  Future<RoomGameLobbyData> leaveSession({
    required int roomId,
    required int sessionId,
  }) async {
    final entry = _sessionByKey.entries.firstWhere(
      (item) => item.value.id == sessionId,
    );
    final players = entry.value.players
        .where((player) => player.userId != 1)
        .toList();
    if (players.isEmpty) {
      _sessionByKey.remove(entry.key);
      return loadLobby(roomId: roomId, gameId: entry.value.gameId);
    }

    _sessionByKey[entry.key] = RoomGameSessionData(
      id: entry.value.id,
      roomId: entry.value.roomId,
      gameId: entry.value.gameId,
      playerCount: players.length,
      maxPlayers: entry.value.maxPlayers,
      status: entry.value.status,
      statusLabel: entry.value.statusLabel,
      createdAt: entry.value.createdAt,
      hostName: entry.value.hostName,
      players: players,
      isJoined: false,
    );
    return loadLobby(roomId: roomId, gameId: entry.value.gameId);
  }

  RoomGameItemData _gameFor(int roomId, int gameId) {
    return (_catalogByRoom[roomId] ?? const <RoomGameItemData>[]).firstWhere(
      (game) => game.id == gameId,
    );
  }

  String _catalogKey(int roomId, int gameId) => '$roomId:$gameId';
}

int _gameAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
