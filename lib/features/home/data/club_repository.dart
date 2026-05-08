import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class ClubImageDraft {
  const ClubImageDraft({
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

class ClubData {
  const ClubData({
    required this.id,
    required this.name,
    required this.code,
    required this.announcementText,
    required this.ownerUserId,
    required this.ownerName,
    required this.avatarAsset,
    required this.membersCount,
    required this.roomsCount,
    required this.rankingPoints,
    required this.status,
    required this.isMember,
    required this.isOwner,
    required this.role,
    required this.createdAtLabel,
  });

  final int id;
  final String name;
  final String code;
  final String announcementText;
  final int? ownerUserId;
  final String ownerName;
  final String avatarAsset;
  final int membersCount;
  final int roomsCount;
  final int rankingPoints;
  final String status;
  final bool isMember;
  final bool isOwner;
  final String role;
  final String createdAtLabel;

  factory ClubData.fromJson(Map<String, dynamic> json) {
    return ClubData(
      id: _clubAsInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      announcementText: json['announcement_text']?.toString() ?? '',
      ownerUserId: json['owner_user_id'] == null
          ? null
          : _clubAsInt(json['owner_user_id']),
      ownerName: json['owner_name']?.toString() ?? 'Hallo Party',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/home_club_icon.png',
      membersCount: _clubAsInt(json['members_count']),
      roomsCount: _clubAsInt(json['rooms_count']),
      rankingPoints: _clubAsInt(json['ranking_points']),
      status: json['status']?.toString() ?? 'active',
      isMember: json['is_member'] == true || _clubAsInt(json['is_member']) == 1,
      isOwner: json['is_owner'] == true || _clubAsInt(json['is_owner']) == 1,
      role: json['role']?.toString() ?? '',
      createdAtLabel: json['created_at_label']?.toString() ?? '',
    );
  }

  ClubData copyWith({
    int? id,
    String? name,
    String? code,
    String? announcementText,
    int? ownerUserId,
    String? ownerName,
    String? avatarAsset,
    int? membersCount,
    int? roomsCount,
    int? rankingPoints,
    String? status,
    bool? isMember,
    bool? isOwner,
    String? role,
    String? createdAtLabel,
  }) {
    return ClubData(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      announcementText: announcementText ?? this.announcementText,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      ownerName: ownerName ?? this.ownerName,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      membersCount: membersCount ?? this.membersCount,
      roomsCount: roomsCount ?? this.roomsCount,
      rankingPoints: rankingPoints ?? this.rankingPoints,
      status: status ?? this.status,
      isMember: isMember ?? this.isMember,
      isOwner: isOwner ?? this.isOwner,
      role: role ?? this.role,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
    );
  }
}

class ClubMemberData {
  const ClubMemberData({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.avatarAsset,
    required this.role,
    required this.joinedAtLabel,
  });

  final int id;
  final int? userId;
  final String nickname;
  final String avatarAsset;
  final String role;
  final String joinedAtLabel;

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';

  factory ClubMemberData.fromJson(Map<String, dynamic> json) {
    return ClubMemberData(
      id: _clubAsInt(json['id']),
      userId: json['user_id'] == null ? null : _clubAsInt(json['user_id']),
      nickname: json['nickname']?.toString() ?? 'Hallo Party User',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      role: json['role']?.toString() ?? 'member',
      joinedAtLabel: json['joined_at_label']?.toString() ?? '',
    );
  }
}

class ClubFeedItemData {
  const ClubFeedItemData({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.authorAvatarAsset,
    required this.bodyText,
    required this.createdAtLabel,
  });

  final int id;
  final int? authorUserId;
  final String authorName;
  final String authorAvatarAsset;
  final String bodyText;
  final String createdAtLabel;

  factory ClubFeedItemData.fromJson(Map<String, dynamic> json) {
    return ClubFeedItemData(
      id: _clubAsInt(json['id']),
      authorUserId: json['author_user_id'] == null
          ? null
          : _clubAsInt(json['author_user_id']),
      authorName: json['author_name']?.toString() ?? 'Hallo Party',
      authorAvatarAsset:
          json['author_avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      bodyText: json['body_text']?.toString() ?? '',
      createdAtLabel: json['created_at_label']?.toString() ?? '',
    );
  }
}

class ClubDetailData {
  const ClubDetailData({
    required this.club,
    required this.members,
    required this.feed,
  });

  final ClubData club;
  final List<ClubMemberData> members;
  final List<ClubFeedItemData> feed;
}

abstract class ClubRepository {
  static ClubRepository instance = LiveClubRepository();

  Future<List<ClubData>> listClubs({
    String scope = 'trending',
    String query = '',
  });

  Future<ClubDetailData> loadClub(int clubId);

  Future<ClubData> createClub({
    required String name,
    required String code,
    required String announcementText,
    String avatarAsset = 'assets/images/home_club_icon.png',
    ClubImageDraft? avatarDraft,
  });

  Future<ClubData> joinClub(int clubId);

  Future<ClubData> leaveClub(int clubId);

  Future<ClubDetailData> postAnnouncement({
    required int clubId,
    required String bodyText,
  });
}

final class LiveClubRepository implements ClubRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<List<ClubData>> listClubs({
    String scope = 'trending',
    String query = '',
  }) async {
    final encodedScope = Uri.encodeQueryComponent(scope);
    final encodedQuery = Uri.encodeQueryComponent(query);
    final response = await _client.get(
      '/clubs?scope=$encodedScope&query=$encodedQuery',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['clubs'] as List? ?? const <dynamic>[])
        .map(
          (item) => ClubData.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<ClubDetailData> loadClub(int clubId) async {
    final response = await _client.get(
      '/clubs/$clubId',
      bearerToken: _authStore.authToken,
    );
    return _detailFromResponse(response);
  }

  @override
  Future<ClubData> createClub({
    required String name,
    required String code,
    required String announcementText,
    String avatarAsset = 'assets/images/home_club_icon.png',
    ClubImageDraft? avatarDraft,
  }) async {
    final response = await _client.post(
      '/clubs',
      body: {
        'name': name,
        'code': code,
        'announcement_text': announcementText,
        'avatar_asset': avatarAsset,
        'avatar_upload': avatarDraft?.toJson(),
      },
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ClubData.fromJson(Map<String, dynamic>.from(data['club'] as Map));
  }

  @override
  Future<ClubData> joinClub(int clubId) async {
    final response = await _client.post(
      '/clubs/$clubId/join',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ClubData.fromJson(Map<String, dynamic>.from(data['club'] as Map));
  }

  @override
  Future<ClubData> leaveClub(int clubId) async {
    final response = await _client.post(
      '/clubs/$clubId/leave',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ClubData.fromJson(Map<String, dynamic>.from(data['club'] as Map));
  }

  @override
  Future<ClubDetailData> postAnnouncement({
    required int clubId,
    required String bodyText,
  }) async {
    final response = await _client.post(
      '/clubs/$clubId/posts',
      body: {'body_text': bodyText},
      bearerToken: _authStore.authToken,
    );
    return _detailFromResponse(response);
  }

  ClubDetailData _detailFromResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;
    return ClubDetailData(
      club: ClubData.fromJson(Map<String, dynamic>.from(data['club'] as Map)),
      members: (data['members'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                ClubMemberData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      feed: (data['feed'] as List? ?? const <dynamic>[])
          .map(
            (item) => ClubFeedItemData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

final class FakeClubRepository implements ClubRepository {
  FakeClubRepository() {
    _seed();
  }

  final Map<int, ClubData> _clubs = <int, ClubData>{};
  final Map<int, List<ClubMemberData>> _members = <int, List<ClubMemberData>>{};
  final Map<int, List<ClubFeedItemData>> _feed =
      <int, List<ClubFeedItemData>>{};
  int _nextClubId = 4;
  int _nextMemberId = 20;
  int _nextFeedId = 30;

  void _seed() {
    if (_clubs.isNotEmpty) {
      return;
    }

    _clubs[1] = const ClubData(
      id: 1,
      name: 'نادي ملوك هالو',
      code: 'HALLO',
      announcementText: 'مسابقات وغرف يومية لأعضاء النادي.',
      ownerUserId: 1,
      ownerName: 'محمد أحمد',
      avatarAsset: 'assets/images/home_club_icon.png',
      membersCount: 1280,
      roomsCount: 12,
      rankingPoints: 89500,
      status: 'active',
      isMember: true,
      isOwner: true,
      role: 'owner',
      createdAtLabel: 'اليوم',
    );
    _clubs[2] = const ClubData(
      id: 2,
      name: 'نادي الأصدقاء',
      code: 'FRIENDS',
      announcementText: 'تعالوا نتجمع في غرف صوتية ولايفات يومية.',
      ownerUserId: 2,
      ownerName: 'Amir Tallal',
      avatarAsset: 'assets/images/profile_avatar.png',
      membersCount: 640,
      roomsCount: 5,
      rankingPoints: 43000,
      status: 'active',
      isMember: false,
      isOwner: false,
      role: '',
      createdAtLabel: 'أمس',
    );
    _clubs[3] = const ClubData(
      id: 3,
      name: 'مزيكا لايف',
      code: 'MUSIC',
      announcementText: 'غناء ومزيكا وتحديات PK طول الأسبوع.',
      ownerUserId: 3,
      ownerName: 'Yara',
      avatarAsset: 'assets/images/home_room_1.png',
      membersCount: 420,
      roomsCount: 4,
      rankingPoints: 28500,
      status: 'active',
      isMember: false,
      isOwner: false,
      role: '',
      createdAtLabel: 'هذا الأسبوع',
    );

    for (final club in _clubs.values) {
      _members[club.id] = <ClubMemberData>[
        ClubMemberData(
          id: _nextMemberId++,
          userId: club.ownerUserId,
          nickname: club.ownerName,
          avatarAsset: club.avatarAsset,
          role: 'owner',
          joinedAtLabel: club.createdAtLabel,
        ),
        ClubMemberData(
          id: _nextMemberId++,
          userId: 4,
          nickname: 'Hallo Party User',
          avatarAsset: 'assets/images/profile_avatar.png',
          role: 'member',
          joinedAtLabel: 'اليوم',
        ),
      ];
      _feed[club.id] = <ClubFeedItemData>[
        ClubFeedItemData(
          id: _nextFeedId++,
          authorUserId: club.ownerUserId,
          authorName: club.ownerName,
          authorAvatarAsset: club.avatarAsset,
          bodyText: club.announcementText,
          createdAtLabel: club.createdAtLabel,
        ),
      ];
    }
  }

  @override
  Future<List<ClubData>> listClubs({
    String scope = 'trending',
    String query = '',
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final clubs = _clubs.values
        .where(
          (club) =>
              normalizedQuery.isEmpty ||
              club.name.toLowerCase().contains(normalizedQuery) ||
              club.code.toLowerCase().contains(normalizedQuery),
        )
        .toList();

    if (scope == 'mine') {
      clubs.removeWhere((club) => !club.isMember && !club.isOwner);
    }
    if (scope == 'newest') {
      clubs.sort((a, b) => b.id.compareTo(a.id));
      return clubs;
    }

    clubs.sort((a, b) => b.rankingPoints.compareTo(a.rankingPoints));
    return clubs;
  }

  @override
  Future<ClubDetailData> loadClub(int clubId) async {
    return ClubDetailData(
      club: _clubs[clubId] ?? _clubs.values.first,
      members: List<ClubMemberData>.of(_members[clubId] ?? const []),
      feed: List<ClubFeedItemData>.of(_feed[clubId] ?? const []),
    );
  }

  @override
  Future<ClubData> createClub({
    required String name,
    required String code,
    required String announcementText,
    String avatarAsset = 'assets/images/home_club_icon.png',
    ClubImageDraft? avatarDraft,
  }) async {
    final user = AuthFlowStore.instance.currentUser;
    final id = _nextClubId++;
    final club = ClubData(
      id: id,
      name: name,
      code: code.toUpperCase(),
      announcementText: announcementText,
      ownerUserId: _clubAsNullableInt(user?['id']),
      ownerName:
          user?['nickname']?.toString() ??
          user?['email']?.toString() ??
          'Hallo Party User',
      avatarAsset: avatarAsset,
      membersCount: 1,
      roomsCount: 0,
      rankingPoints: 500,
      status: 'active',
      isMember: true,
      isOwner: true,
      role: 'owner',
      createdAtLabel: 'الآن',
    );
    _clubs[id] = club;
    _members[id] = <ClubMemberData>[
      ClubMemberData(
        id: _nextMemberId++,
        userId: club.ownerUserId,
        nickname: club.ownerName,
        avatarAsset: club.avatarAsset,
        role: 'owner',
        joinedAtLabel: 'الآن',
      ),
    ];
    _feed[id] = <ClubFeedItemData>[
      ClubFeedItemData(
        id: _nextFeedId++,
        authorUserId: club.ownerUserId,
        authorName: club.ownerName,
        authorAvatarAsset: club.avatarAsset,
        bodyText: announcementText.isEmpty
            ? 'تم إنشاء النادي بنجاح.'
            : announcementText,
        createdAtLabel: 'الآن',
      ),
    ];
    return club;
  }

  @override
  Future<ClubData> joinClub(int clubId) async {
    final club = _clubs[clubId] ?? _clubs.values.first;
    if (club.isMember) {
      return club;
    }
    final updated = club.copyWith(
      isMember: true,
      role: 'member',
      membersCount: club.membersCount + 1,
      rankingPoints: club.rankingPoints + 20,
    );
    _clubs[club.id] = updated;
    _members[club.id] = <ClubMemberData>[
      ...(_members[club.id] ?? const <ClubMemberData>[]),
      ClubMemberData(
        id: _nextMemberId++,
        userId: _clubAsNullableInt(AuthFlowStore.instance.currentUser?['id']),
        nickname:
            AuthFlowStore.instance.currentUser?['nickname']?.toString() ??
            'Hallo Party User',
        avatarAsset:
            AuthFlowStore.instance.currentUser?['avatar_asset']?.toString() ??
            'assets/images/profile_avatar.png',
        role: 'member',
        joinedAtLabel: 'الآن',
      ),
    ];
    return updated;
  }

  @override
  Future<ClubData> leaveClub(int clubId) async {
    final club = _clubs[clubId] ?? _clubs.values.first;
    if (club.isOwner) {
      return club;
    }
    final updated = club.copyWith(
      isMember: false,
      role: '',
      membersCount: club.membersCount > 0 ? club.membersCount - 1 : 0,
    );
    _clubs[club.id] = updated;
    return updated;
  }

  @override
  Future<ClubDetailData> postAnnouncement({
    required int clubId,
    required String bodyText,
  }) async {
    final club = _clubs[clubId] ?? _clubs.values.first;
    _feed[club.id] = <ClubFeedItemData>[
      ClubFeedItemData(
        id: _nextFeedId++,
        authorUserId: club.ownerUserId,
        authorName: club.ownerName,
        authorAvatarAsset: club.avatarAsset,
        bodyText: bodyText,
        createdAtLabel: 'الآن',
      ),
      ...(_feed[club.id] ?? const <ClubFeedItemData>[]),
    ];
    return loadClub(club.id);
  }
}

int _clubAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _clubAsNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  return _clubAsInt(value);
}
