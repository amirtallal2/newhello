import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class ProfileAvatarDraft {
  const ProfileAvatarDraft({
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

class ProfileUserData {
  const ProfileUserData({
    required this.id,
    required this.email,
    required this.phone,
    required this.nickname,
    required this.birthdate,
    required this.gender,
    required this.country,
    required this.status,
    required this.authProvider,
    required this.emailVerified,
    required this.phoneVerified,
    required this.profileHandle,
    required this.signatureText,
    required this.avatarAsset,
    required this.agencyId,
    required this.agencyRole,
  });

  final int id;
  final String? email;
  final String? phone;
  final String nickname;
  final String? birthdate;
  final String? gender;
  final String country;
  final String status;
  final String authProvider;
  final bool emailVerified;
  final bool phoneVerified;
  final String profileHandle;
  final String signatureText;
  final String avatarAsset;
  final int? agencyId;
  final String? agencyRole;

  factory ProfileUserData.fromJson(Map<String, dynamic> json) {
    return ProfileUserData(
      id: _asInt(json['id']),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      nickname: json['nickname']?.toString() ?? 'بدون اسم',
      birthdate: json['birthdate']?.toString(),
      gender: json['gender']?.toString(),
      country: json['country']?.toString() ?? 'Egypt',
      status: json['status']?.toString() ?? 'active',
      authProvider: json['auth_provider']?.toString() ?? 'password',
      emailVerified: _asBool(json['email_verified']),
      phoneVerified: _asBool(json['phone_verified']),
      profileHandle: json['profile_handle']?.toString() ?? 'Shark.island',
      signatureText:
          json['signature_text']?.toString() ?? 'ليس لديك المقدمة الشخصية',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      agencyId: json['agency_id'] == null ? null : _asInt(json['agency_id']),
      agencyRole: json['agency_role']?.toString(),
    );
  }

  Map<String, dynamic> toSessionJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'nickname': nickname,
      'birthdate': birthdate,
      'gender': gender,
      'country': country,
      'status': status,
      'auth_provider': authProvider,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'profile_handle': profileHandle,
      'signature_text': signatureText,
      'avatar_asset': avatarAsset,
      'agency_id': agencyId,
      'agency_role': agencyRole,
    };
  }
}

class ProfileStatsData {
  const ProfileStatsData({
    required this.followingCount,
    required this.followersCount,
    required this.friendsCount,
  });

  final int followingCount;
  final int followersCount;
  final int friendsCount;

  factory ProfileStatsData.fromJson(Map<String, dynamic> json) {
    return ProfileStatsData(
      followingCount: _asInt(json['following_count'], fallback: 50),
      followersCount: _asInt(json['followers_count'], fallback: 100),
      friendsCount: _asInt(json['friends_count'], fallback: 123),
    );
  }
}

class ProfileStatusData {
  const ProfileStatusData({
    required this.levelCurrent,
    required this.levelNext,
    required this.levelProgressPercent,
    required this.vipTier,
    required this.svipTier,
    required this.badgesCount,
    required this.tasksCompleted,
    required this.tasksTotal,
  });

  final int levelCurrent;
  final int levelNext;
  final int levelProgressPercent;
  final String vipTier;
  final String svipTier;
  final int badgesCount;
  final int tasksCompleted;
  final int tasksTotal;

  factory ProfileStatusData.fromJson(Map<String, dynamic> json) {
    return ProfileStatusData(
      levelCurrent: _asInt(json['level_current']),
      levelNext: _asInt(json['level_next'], fallback: 1),
      levelProgressPercent: _asInt(
        json['level_progress_percent'],
        fallback: 67,
      ),
      vipTier: json['vip_tier']?.toString() ?? 'VIP 0',
      svipTier: json['svip_tier']?.toString() ?? 'SVIP 0',
      badgesCount: _asInt(json['badges_count'], fallback: 4),
      tasksCompleted: _asInt(json['tasks_completed'], fallback: 5),
      tasksTotal: _asInt(json['tasks_total'], fallback: 12),
    );
  }
}

class ProfileSettingsData {
  const ProfileSettingsData({
    required this.privateProfile,
    required this.allowDirectMessages,
    required this.showOnlineStatus,
    required this.receiveChatNotifications,
    required this.receiveLiveNotifications,
    required this.receiveRoomInvites,
    required this.receivePartyInvites,
    required this.preferredLanguage,
  });

  final bool privateProfile;
  final bool allowDirectMessages;
  final bool showOnlineStatus;
  final bool receiveChatNotifications;
  final bool receiveLiveNotifications;
  final bool receiveRoomInvites;
  final bool receivePartyInvites;
  final String preferredLanguage;

  factory ProfileSettingsData.fromJson(Map<String, dynamic> json) {
    return ProfileSettingsData(
      privateProfile: _asBool(json['private_profile']),
      allowDirectMessages: _asBool(
        json['allow_direct_messages'],
        fallback: true,
      ),
      showOnlineStatus: _asBool(json['show_online_status'], fallback: true),
      receiveChatNotifications: _asBool(
        json['receive_chat_notifications'],
        fallback: true,
      ),
      receiveLiveNotifications: _asBool(
        json['receive_live_notifications'],
        fallback: true,
      ),
      receiveRoomInvites: _asBool(json['receive_room_invites'], fallback: true),
      receivePartyInvites: _asBool(
        json['receive_party_invites'],
        fallback: true,
      ),
      preferredLanguage: json['preferred_language']?.toString() ?? 'ar',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'private_profile': privateProfile,
      'allow_direct_messages': allowDirectMessages,
      'show_online_status': showOnlineStatus,
      'receive_chat_notifications': receiveChatNotifications,
      'receive_live_notifications': receiveLiveNotifications,
      'receive_room_invites': receiveRoomInvites,
      'receive_party_invites': receivePartyInvites,
      'preferred_language': preferredLanguage,
    };
  }

  ProfileSettingsData copyWith({
    bool? privateProfile,
    bool? allowDirectMessages,
    bool? showOnlineStatus,
    bool? receiveChatNotifications,
    bool? receiveLiveNotifications,
    bool? receiveRoomInvites,
    bool? receivePartyInvites,
    String? preferredLanguage,
  }) {
    return ProfileSettingsData(
      privateProfile: privateProfile ?? this.privateProfile,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      receiveChatNotifications:
          receiveChatNotifications ?? this.receiveChatNotifications,
      receiveLiveNotifications:
          receiveLiveNotifications ?? this.receiveLiveNotifications,
      receiveRoomInvites: receiveRoomInvites ?? this.receiveRoomInvites,
      receivePartyInvites: receivePartyInvites ?? this.receivePartyInvites,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}

class ProfileAppearanceData {
  const ProfileAppearanceData({
    this.avatarFrameAssetPath,
    this.chatFrameAssetPath,
    this.profileBadgeAssetPath,
    this.backgroundAssetPath,
    this.entryEffectAssetPath,
  });

  final String? avatarFrameAssetPath;
  final String? chatFrameAssetPath;
  final String? profileBadgeAssetPath;
  final String? backgroundAssetPath;
  final String? entryEffectAssetPath;

  factory ProfileAppearanceData.fromJson(Map<String, dynamic> json) {
    return ProfileAppearanceData(
      avatarFrameAssetPath: _nullableString(json['avatar_frame_asset_path']),
      chatFrameAssetPath: _nullableString(json['chat_frame_asset_path']),
      profileBadgeAssetPath: _nullableString(json['profile_badge_asset_path']),
      backgroundAssetPath: _nullableString(json['background_asset_path']),
      entryEffectAssetPath: _nullableString(json['entry_effect_asset_path']),
    );
  }
}

class ProfileSummaryData {
  const ProfileSummaryData({
    required this.user,
    required this.stats,
    required this.status,
    required this.settings,
    this.appearance = const ProfileAppearanceData(),
  });

  final ProfileUserData user;
  final ProfileStatsData stats;
  final ProfileStatusData status;
  final ProfileSettingsData settings;
  final ProfileAppearanceData appearance;

  factory ProfileSummaryData.fromJson(Map<String, dynamic> json) {
    return ProfileSummaryData(
      user: ProfileUserData.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
      stats: ProfileStatsData.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? const {}),
      ),
      status: ProfileStatusData.fromJson(
        Map<String, dynamic>.from(json['status'] as Map? ?? const {}),
      ),
      settings: ProfileSettingsData.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? const {}),
      ),
      appearance: ProfileAppearanceData.fromJson(
        Map<String, dynamic>.from(json['appearance'] as Map? ?? const {}),
      ),
    );
  }
}

abstract class ProfileAccountRepository {
  static ProfileAccountRepository instance = LiveProfileAccountRepository();

  Future<ProfileSummaryData> loadSummary();

  Future<ProfileSummaryData> loadUserSummary({required int userId});

  Future<ProfileSummaryData> updateProfile({
    required String nickname,
    String? email,
    String? phone,
    required String birthdate,
    String? gender,
    required String country,
    required String signatureText,
    required String profileHandle,
    required String avatarAsset,
    ProfileAvatarDraft? avatarDraft,
  });

  Future<ProfileSummaryData> updateSettings(ProfileSettingsData settings);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

final class LiveProfileAccountRepository implements ProfileAccountRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<ProfileSummaryData> loadSummary() async {
    final response = await _client.get(
      '/profile/summary',
      bearerToken: _authStore.authToken,
    );
    return _syncSummary(
      ProfileSummaryData.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      ),
    );
  }

  @override
  Future<ProfileSummaryData> loadUserSummary({required int userId}) async {
    final response = await _client.get(
      '/profile/users/$userId/summary',
      bearerToken: _authStore.authToken,
    );
    return ProfileSummaryData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<ProfileSummaryData> updateProfile({
    required String nickname,
    String? email,
    String? phone,
    required String birthdate,
    String? gender,
    required String country,
    required String signatureText,
    required String profileHandle,
    required String avatarAsset,
    ProfileAvatarDraft? avatarDraft,
  }) async {
    final response = await _client.post(
      '/profile',
      body: {
        'nickname': nickname,
        'email': email,
        'phone': phone,
        'birthdate': birthdate,
        'gender': gender,
        'country': country,
        'signature_text': signatureText,
        'profile_handle': profileHandle,
        'avatar_asset': avatarAsset,
        'avatar_upload': avatarDraft?.toJson(),
      },
      bearerToken: _authStore.authToken,
    );
    return _syncSummary(
      ProfileSummaryData.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      ),
    );
  }

  @override
  Future<ProfileSummaryData> updateSettings(
    ProfileSettingsData settings,
  ) async {
    final response = await _client.post(
      '/profile/settings',
      body: settings.toJson(),
      bearerToken: _authStore.authToken,
    );
    return _syncSummary(
      ProfileSummaryData.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      ),
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.post(
      '/profile/password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      bearerToken: _authStore.authToken,
    );
  }

  Future<ProfileSummaryData> _syncSummary(ProfileSummaryData summary) async {
    final token = _authStore.authToken;
    if (token != null && token.isNotEmpty) {
      await _authStore.saveAuthSession(
        token: token,
        user: summary.user.toSessionJson(),
      );
    }
    return summary;
  }
}

final class FakeProfileAccountRepository implements ProfileAccountRepository {
  ProfileSummaryData _summary = ProfileSummaryData(
    user: const ProfileUserData(
      id: 1512345412,
      email: 'profile@example.com',
      phone: '201001112233',
      nickname: 'بسمة أحمد',
      birthdate: '2004-09-20',
      gender: 'أنثى',
      country: 'Egypt',
      status: 'active',
      authProvider: 'password',
      emailVerified: true,
      phoneVerified: true,
      profileHandle: 'Shark.island',
      signatureText: 'ليس لديك المقدمة الشخصية',
      avatarAsset: 'assets/images/profile_avatar.png',
      agencyId: 1,
      agencyRole: 'owner',
    ),
    stats: const ProfileStatsData(
      followingCount: 50,
      followersCount: 100,
      friendsCount: 123,
    ),
    status: const ProfileStatusData(
      levelCurrent: 0,
      levelNext: 1,
      levelProgressPercent: 67,
      vipTier: 'VIP 0',
      svipTier: 'SVIP 0',
      badgesCount: 4,
      tasksCompleted: 5,
      tasksTotal: 12,
    ),
    settings: const ProfileSettingsData(
      privateProfile: false,
      allowDirectMessages: true,
      showOnlineStatus: true,
      receiveChatNotifications: true,
      receiveLiveNotifications: true,
      receiveRoomInvites: true,
      receivePartyInvites: true,
      preferredLanguage: 'ar',
    ),
    appearance: const ProfileAppearanceData(
      avatarFrameAssetPath:
          'assets/images/profile_store_frames_preview_overlay.png',
      profileBadgeAssetPath: 'assets/images/profile_store_aristocracy_icon.png',
    ),
  );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      throw Exception('كلمتا المرور غير متطابقتين');
    }
    if (newPassword.trim().length < 6) {
      throw Exception('كلمة المرور الجديدة يجب ألا تقل عن 6 أحرف');
    }
  }

  @override
  Future<ProfileSummaryData> loadSummary() async => _summary;

  @override
  Future<ProfileSummaryData> loadUserSummary({required int userId}) async {
    if (userId == _summary.user.id) {
      return _summary;
    }

    return ProfileSummaryData(
      user: ProfileUserData(
        id: userId,
        email: null,
        phone: null,
        nickname: userId == 2 ? 'اسماء فتحي' : 'مستخدم Hallo Party',
        birthdate: null,
        gender: null,
        country: 'Egypt',
        status: 'active',
        authProvider: 'password',
        emailVerified: false,
        phoneVerified: false,
        profileHandle: 'ID:$userId',
        signatureText: 'ليس لديك المقدمة الشخصية',
        avatarAsset: 'assets/images/post_author_avatar.png',
        agencyId: null,
        agencyRole: null,
      ),
      stats: const ProfileStatsData(
        followingCount: 0,
        followersCount: 0,
        friendsCount: 0,
      ),
      status: const ProfileStatusData(
        levelCurrent: 0,
        levelNext: 1,
        levelProgressPercent: 0,
        vipTier: 'VIP 0',
        svipTier: 'SVIP 0',
        badgesCount: 0,
        tasksCompleted: 0,
        tasksTotal: 1,
      ),
      settings: const ProfileSettingsData(
        privateProfile: false,
        allowDirectMessages: true,
        showOnlineStatus: true,
        receiveChatNotifications: true,
        receiveLiveNotifications: true,
        receiveRoomInvites: true,
        receivePartyInvites: true,
        preferredLanguage: 'ar',
      ),
      appearance: const ProfileAppearanceData(
        avatarFrameAssetPath:
            'assets/images/profile_store_frames_preview_overlay.png',
      ),
    );
  }

  @override
  Future<ProfileSummaryData> updateProfile({
    required String nickname,
    String? email,
    String? phone,
    required String birthdate,
    String? gender,
    required String country,
    required String signatureText,
    required String profileHandle,
    required String avatarAsset,
    ProfileAvatarDraft? avatarDraft,
  }) async {
    final nextAvatar = avatarDraft == null
        ? avatarAsset
        : '/storage/profile/${avatarDraft.fileName}';
    _summary = ProfileSummaryData(
      user: ProfileUserData(
        id: _summary.user.id,
        email: email ?? _summary.user.email,
        phone: phone ?? _summary.user.phone,
        nickname: nickname,
        birthdate: birthdate.isEmpty ? null : birthdate,
        gender: gender ?? _summary.user.gender,
        country: country,
        status: _summary.user.status,
        authProvider: _summary.user.authProvider,
        emailVerified: _summary.user.emailVerified,
        phoneVerified: _summary.user.phoneVerified,
        profileHandle: profileHandle,
        signatureText: signatureText.isEmpty
            ? 'ليس لديك المقدمة الشخصية'
            : signatureText,
        avatarAsset: nextAvatar,
        agencyId: _summary.user.agencyId,
        agencyRole: _summary.user.agencyRole,
      ),
      stats: _summary.stats,
      status: _summary.status,
      settings: _summary.settings,
      appearance: _summary.appearance,
    );
    return _summary;
  }

  @override
  Future<ProfileSummaryData> updateSettings(
    ProfileSettingsData settings,
  ) async {
    _summary = ProfileSummaryData(
      user: _summary.user,
      stats: _summary.stats,
      status: _summary.status,
      settings: settings,
    );
    return _summary;
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _asBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return fallback;
  }

  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

String? _nullableString(Object? value) {
  final stringValue = value?.toString().trim();
  if (stringValue == null || stringValue.isEmpty) {
    return null;
  }
  return stringValue;
}
