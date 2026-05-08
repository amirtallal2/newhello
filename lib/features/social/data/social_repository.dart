import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

enum SocialConnectionType { following, followers, friends }

extension SocialConnectionTypeWire on SocialConnectionType {
  String get wireName {
    switch (this) {
      case SocialConnectionType.following:
        return 'following';
      case SocialConnectionType.followers:
        return 'followers';
      case SocialConnectionType.friends:
        return 'friends';
    }
  }
}

class SocialStatsData {
  const SocialStatsData({
    required this.followingCount,
    required this.followersCount,
    required this.friendsCount,
  });

  final int followingCount;
  final int followersCount;
  final int friendsCount;

  factory SocialStatsData.fromJson(Map<String, dynamic> json) {
    return SocialStatsData(
      followingCount: _socialAsInt(json['following_count']),
      followersCount: _socialAsInt(json['followers_count']),
      friendsCount: _socialAsInt(json['friends_count']),
    );
  }
}

class SocialRelationshipData {
  const SocialRelationshipData({
    required this.status,
    required this.isSelf,
    required this.isFollowing,
    required this.isFollowedBy,
    required this.isFriend,
  });

  final String status;
  final bool isSelf;
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isFriend;

  factory SocialRelationshipData.fromJson(Map<String, dynamic> json) {
    return SocialRelationshipData(
      status: json['status']?.toString() ?? 'none',
      isSelf: json['is_self'] == true,
      isFollowing: json['is_following'] == true,
      isFollowedBy: json['is_followed_by'] == true,
      isFriend: json['is_friend'] == true,
    );
  }
}

class SocialUserData {
  const SocialUserData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatarAsset,
    required this.country,
    required this.stats,
    required this.relationship,
  });

  final int id;
  final String name;
  final String subtitle;
  final String avatarAsset;
  final String country;
  final SocialStatsData stats;
  final SocialRelationshipData relationship;

  factory SocialUserData.fromJson(Map<String, dynamic> json) {
    return SocialUserData(
      id: _socialAsInt(json['id']),
      name:
          json['name']?.toString() ??
          json['nickname']?.toString() ??
          'Hallo Party User',
      subtitle:
          json['subtitle']?.toString() ?? 'ID:${_socialAsInt(json['id'])}',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      country: json['country']?.toString() ?? 'Egypt',
      stats: SocialStatsData.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? const {}),
      ),
      relationship: SocialRelationshipData.fromJson(
        Map<String, dynamic>.from(json['relationship'] as Map? ?? const {}),
      ),
    );
  }
}

class SocialConnectionsData {
  const SocialConnectionsData({required this.stats, required this.users});

  final SocialStatsData stats;
  final List<SocialUserData> users;

  factory SocialConnectionsData.fromJson(Map<String, dynamic> json) {
    return SocialConnectionsData(
      stats: SocialStatsData.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? const {}),
      ),
      users: (json['users'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                SocialUserData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class SocialActionResult {
  const SocialActionResult({
    required this.user,
    required this.viewerStats,
    required this.targetStats,
  });

  final SocialUserData user;
  final SocialStatsData viewerStats;
  final SocialStatsData targetStats;

  factory SocialActionResult.fromJson(Map<String, dynamic> json) {
    return SocialActionResult(
      user: SocialUserData.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
      viewerStats: SocialStatsData.fromJson(
        Map<String, dynamic>.from(json['viewer_stats'] as Map? ?? const {}),
      ),
      targetStats: SocialStatsData.fromJson(
        Map<String, dynamic>.from(json['target_stats'] as Map? ?? const {}),
      ),
    );
  }
}

abstract class SocialRepository {
  static SocialRepository instance = LiveSocialRepository();

  Future<SocialConnectionsData> loadConnections({
    required SocialConnectionType type,
    int? userId,
  });

  Future<List<SocialUserData>> searchUsers({required String query});

  Future<SocialActionResult> toggleFollow({required int userId});
}

final class LiveSocialRepository implements SocialRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<SocialConnectionsData> loadConnections({
    required SocialConnectionType type,
    int? userId,
  }) async {
    final userQuery = userId == null ? '' : '&user_id=$userId';
    final response = await _client.get(
      '/social/connections?type=${type.wireName}$userQuery',
      bearerToken: _authStore.authToken,
    );

    return SocialConnectionsData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<List<SocialUserData>> searchUsers({required String query}) async {
    final response = await _client.get(
      '/social/search?query=${Uri.encodeQueryComponent(query)}',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['users'] as List? ?? const <dynamic>[])
        .map(
          (item) =>
              SocialUserData.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<SocialActionResult> toggleFollow({required int userId}) async {
    final response = await _client.post(
      '/social/users/$userId/follow-toggle',
      bearerToken: _authStore.authToken,
    );

    return SocialActionResult.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

final class FakeSocialRepository implements SocialRepository {
  final List<SocialUserData> _users = <SocialUserData>[
    const SocialUserData(
      id: 2,
      name: 'Yara Mohamed',
      subtitle: 'Shark.island',
      avatarAsset: 'assets/images/profile_store_friend_yara.png',
      country: 'Egypt',
      stats: SocialStatsData(
        followingCount: 1,
        followersCount: 2,
        friendsCount: 1,
      ),
      relationship: SocialRelationshipData(
        status: 'friends',
        isSelf: false,
        isFollowing: true,
        isFollowedBy: true,
        isFriend: true,
      ),
    ),
  ];

  @override
  Future<SocialConnectionsData> loadConnections({
    required SocialConnectionType type,
    int? userId,
  }) async {
    return SocialConnectionsData(
      stats: const SocialStatsData(
        followingCount: 1,
        followersCount: 1,
        friendsCount: 1,
      ),
      users: const <SocialUserData>[],
    );
  }

  @override
  Future<List<SocialUserData>> searchUsers({required String query}) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<SocialUserData>.from(_users);
    }

    return _users
        .where(
          (user) =>
              user.name.toLowerCase().contains(normalized) ||
              user.subtitle.toLowerCase().contains(normalized) ||
              user.country.toLowerCase().contains(normalized),
        )
        .toList();
  }

  @override
  Future<SocialActionResult> toggleFollow({required int userId}) async {
    final user = _users.firstWhere(
      (item) => item.id == userId,
      orElse: () => _users.first,
    );
    return SocialActionResult(
      user: user,
      viewerStats: const SocialStatsData(
        followingCount: 1,
        followersCount: 1,
        friendsCount: 1,
      ),
      targetStats: user.stats,
    );
  }
}

int _socialAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
