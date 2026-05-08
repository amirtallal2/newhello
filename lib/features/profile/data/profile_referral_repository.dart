import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class ProfileReferralUserData {
  const ProfileReferralUserData({
    required this.id,
    required this.name,
    required this.avatarAsset,
    required this.inviteCode,
    required this.inviteLink,
  });

  final int id;
  final String name;
  final String avatarAsset;
  final String inviteCode;
  final String inviteLink;

  factory ProfileReferralUserData.fromJson(Map<String, dynamic> json) {
    return ProfileReferralUserData(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? 'Hallo Party User',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      inviteCode: json['invite_code']?.toString() ?? '',
      inviteLink: json['invite_link']?.toString() ?? '',
    );
  }
}

class ProfileReferralSettingsData {
  const ProfileReferralSettingsData({
    required this.dailyTargetUsd,
    required this.firstWithdrawUsd,
    required this.firstWithdrawDays,
    required this.signupRewardUsd,
    required this.directRechargePercent,
    required this.indirectRechargePercent,
  });

  final double dailyTargetUsd;
  final double firstWithdrawUsd;
  final int firstWithdrawDays;
  final double signupRewardUsd;
  final double directRechargePercent;
  final double indirectRechargePercent;

  factory ProfileReferralSettingsData.fromJson(Map<String, dynamic> json) {
    return ProfileReferralSettingsData(
      dailyTargetUsd: _asDouble(json['daily_target_usd'], fallback: 50),
      firstWithdrawUsd: _asDouble(json['first_withdraw_usd'], fallback: 50),
      firstWithdrawDays: _asInt(json['first_withdraw_days']),
      signupRewardUsd: _asDouble(json['signup_reward_usd'], fallback: 1),
      directRechargePercent: _asDouble(
        json['direct_recharge_percent'],
        fallback: 15,
      ),
      indirectRechargePercent: _asDouble(
        json['indirect_recharge_percent'],
        fallback: 5,
      ),
    );
  }
}

class ProfileReferralAssetsData {
  const ProfileReferralAssetsData({
    required this.headerAsset,
    required this.rewardCardAsset,
    required this.emptyAsset,
  });

  final String headerAsset;
  final String rewardCardAsset;
  final String emptyAsset;

  factory ProfileReferralAssetsData.fromJson(Map<String, dynamic> json) {
    return ProfileReferralAssetsData(
      headerAsset:
          json['header_asset']?.toString() ??
          'https://api.builder.io/api/v1/image/assets/TEMP/f1efcaf22a2d59f5c185fe2e85fe9f5de0c62ae1?width=750',
      rewardCardAsset:
          json['reward_card_asset']?.toString() ??
          'https://api.builder.io/api/v1/image/assets/TEMP/162d7fea0ddaab2b573d9c5341b8a35a9e02bd54?width=654',
      emptyAsset:
          json['empty_asset']?.toString() ??
          'https://api.builder.io/api/v1/image/assets/TEMP/db7ce84fd71af7a6e23fb548746556307a630c39?width=136',
    );
  }
}

class ProfileReferralStatsData {
  const ProfileReferralStatsData({
    required this.dailyTargetUsd,
    required this.firstWithdrawUsd,
    required this.firstWithdrawDays,
    required this.todayInvites,
    required this.totalInvites,
    required this.registeredInvites,
    required this.unknownInvites,
    required this.yesterdayRewardUsd,
    required this.accumulatedRewardUsd,
    required this.availableRewardUsd,
  });

  final double dailyTargetUsd;
  final double firstWithdrawUsd;
  final int firstWithdrawDays;
  final int todayInvites;
  final int totalInvites;
  final int registeredInvites;
  final int unknownInvites;
  final double yesterdayRewardUsd;
  final double accumulatedRewardUsd;
  final double availableRewardUsd;

  factory ProfileReferralStatsData.fromJson(Map<String, dynamic> json) {
    return ProfileReferralStatsData(
      dailyTargetUsd: _asDouble(json['daily_target_usd'], fallback: 50),
      firstWithdrawUsd: _asDouble(json['first_withdraw_usd'], fallback: 50),
      firstWithdrawDays: _asInt(json['first_withdraw_days']),
      todayInvites: _asInt(json['today_invites']),
      totalInvites: _asInt(json['total_invites']),
      registeredInvites: _asInt(json['registered_invites']),
      unknownInvites: _asInt(json['unknown_invites']),
      yesterdayRewardUsd: _asDouble(json['yesterday_reward_usd']),
      accumulatedRewardUsd: _asDouble(json['accumulated_reward_usd']),
      availableRewardUsd: _asDouble(json['available_reward_usd']),
    );
  }
}

class ProfileReferralRewardCardData {
  const ProfileReferralRewardCardData({
    required this.title,
    required this.percent,
    required this.description,
  });

  final String title;
  final double percent;
  final String description;

  factory ProfileReferralRewardCardData.fromJson(Map<String, dynamic> json) {
    return ProfileReferralRewardCardData(
      title: json['title']?.toString() ?? 'مكافأة التعبئة',
      percent: _asDouble(json['percent']),
      description: json['description']?.toString() ?? '',
    );
  }
}

class ProfileReferralInviteData {
  const ProfileReferralInviteData({
    required this.id,
    required this.userId,
    required this.name,
    required this.handle,
    required this.avatarAsset,
    required this.status,
    required this.rewardUsd,
    required this.registeredAtLabel,
  });

  final int id;
  final int? userId;
  final String name;
  final String handle;
  final String avatarAsset;
  final String status;
  final double rewardUsd;
  final String registeredAtLabel;

  factory ProfileReferralInviteData.fromJson(Map<String, dynamic> json) {
    return ProfileReferralInviteData(
      id: _asInt(json['id']),
      userId: json['user_id'] == null ? null : _asInt(json['user_id']),
      name: json['name']?.toString() ?? 'صديق جديد',
      handle: json['handle']?.toString() ?? 'Hallo Party',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      status: json['status']?.toString() ?? 'registered',
      rewardUsd: _asDouble(json['reward_usd']),
      registeredAtLabel: json['registered_at_label']?.toString() ?? '',
    );
  }
}

class ProfileReferralRewardTransactionData {
  const ProfileReferralRewardTransactionData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.amountUsd,
    required this.ratePercent,
    required this.status,
    required this.createdAtLabel,
  });

  final int id;
  final String title;
  final String subtitle;
  final String type;
  final double amountUsd;
  final double ratePercent;
  final String status;
  final String createdAtLabel;

  factory ProfileReferralRewardTransactionData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProfileReferralRewardTransactionData(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? 'مكافأة دعوة',
      subtitle: json['subtitle']?.toString() ?? '',
      type: json['type']?.toString() ?? 'signup',
      amountUsd: _asDouble(json['amount_usd']),
      ratePercent: _asDouble(json['rate_percent']),
      status: json['status']?.toString() ?? 'available',
      createdAtLabel: json['created_at_label']?.toString() ?? '',
    );
  }
}

class ProfileReferralLeaderboardData {
  const ProfileReferralLeaderboardData({
    required this.rank,
    required this.userId,
    required this.name,
    required this.handle,
    required this.avatarAsset,
    required this.invitedCount,
    required this.rewardUsd,
  });

  final int rank;
  final int userId;
  final String name;
  final String handle;
  final String avatarAsset;
  final int invitedCount;
  final double rewardUsd;

  factory ProfileReferralLeaderboardData.fromJson(Map<String, dynamic> json) {
    return ProfileReferralLeaderboardData(
      rank: _asInt(json['rank']),
      userId: _asInt(json['user_id']),
      name: json['name']?.toString() ?? 'Hallo Party User',
      handle: json['handle']?.toString() ?? '',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      invitedCount: _asInt(json['invited_count']),
      rewardUsd: _asDouble(json['reward_usd']),
    );
  }
}

class ProfileReferralSummaryData {
  const ProfileReferralSummaryData({
    required this.user,
    required this.settings,
    required this.assets,
    required this.stats,
    required this.rewardCards,
    required this.myInvites,
    required this.rewardTransactions,
    required this.leaderboard,
  });

  final ProfileReferralUserData user;
  final ProfileReferralSettingsData settings;
  final ProfileReferralAssetsData assets;
  final ProfileReferralStatsData stats;
  final List<ProfileReferralRewardCardData> rewardCards;
  final List<ProfileReferralInviteData> myInvites;
  final List<ProfileReferralRewardTransactionData> rewardTransactions;
  final List<ProfileReferralLeaderboardData> leaderboard;

  factory ProfileReferralSummaryData.fromJson(Map<String, dynamic> json) {
    return ProfileReferralSummaryData(
      user: ProfileReferralUserData.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
      settings: ProfileReferralSettingsData.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? const {}),
      ),
      assets: ProfileReferralAssetsData.fromJson(
        Map<String, dynamic>.from(json['assets'] as Map? ?? const {}),
      ),
      stats: ProfileReferralStatsData.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? const {}),
      ),
      rewardCards: (json['reward_cards'] as List? ?? const <dynamic>[])
          .map(
            (item) => ProfileReferralRewardCardData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      myInvites: (json['my_invites'] as List? ?? const <dynamic>[])
          .map(
            (item) => ProfileReferralInviteData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      rewardTransactions:
          (json['reward_transactions'] as List? ?? const <dynamic>[])
              .map(
                (item) => ProfileReferralRewardTransactionData.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false),
      leaderboard: (json['leaderboard'] as List? ?? const <dynamic>[])
          .map(
            (item) => ProfileReferralLeaderboardData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

abstract class ProfileReferralRepository {
  static ProfileReferralRepository instance = LiveProfileReferralRepository();

  Future<ProfileReferralSummaryData> loadSummary();
}

final class LiveProfileReferralRepository implements ProfileReferralRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<ProfileReferralSummaryData> loadSummary() async {
    final response = await _client.get(
      '/referrals/summary',
      bearerToken: _authStore.authToken,
    );
    return ProfileReferralSummaryData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

final class FakeProfileReferralRepository implements ProfileReferralRepository {
  @override
  Future<ProfileReferralSummaryData> loadSummary() async {
    return ProfileReferralSummaryData(
      user: const ProfileReferralUserData(
        id: 1512345412,
        name: 'بسمة أحمد',
        avatarAsset: 'assets/images/profile_avatar.png',
        inviteCode: 'HPABC123',
        inviteLink: 'https://halloparty.online/invite?code=HPABC123',
      ),
      settings: const ProfileReferralSettingsData(
        dailyTargetUsd: 50,
        firstWithdrawUsd: 50,
        firstWithdrawDays: 0,
        signupRewardUsd: 1,
        directRechargePercent: 15,
        indirectRechargePercent: 5,
      ),
      assets: const ProfileReferralAssetsData(
        headerAsset:
            'https://api.builder.io/api/v1/image/assets/TEMP/f1efcaf22a2d59f5c185fe2e85fe9f5de0c62ae1?width=750',
        rewardCardAsset:
            'https://api.builder.io/api/v1/image/assets/TEMP/162d7fea0ddaab2b573d9c5341b8a35a9e02bd54?width=654',
        emptyAsset:
            'https://api.builder.io/api/v1/image/assets/TEMP/db7ce84fd71af7a6e23fb548746556307a630c39?width=136',
      ),
      stats: const ProfileReferralStatsData(
        dailyTargetUsd: 50,
        firstWithdrawUsd: 50,
        firstWithdrawDays: 0,
        todayInvites: 2,
        totalInvites: 9,
        registeredInvites: 7,
        unknownInvites: 0,
        yesterdayRewardUsd: 4,
        accumulatedRewardUsd: 28.5,
        availableRewardUsd: 18,
      ),
      rewardCards: const [
        ProfileReferralRewardCardData(
          title: 'مكافأة التعبئة',
          percent: 15,
          description: 'أرباح مباشرة من شحن الأصدقاء.',
        ),
        ProfileReferralRewardCardData(
          title: 'مكافأة الشبكة',
          percent: 5,
          description: 'أرباح إضافية من شحن أصدقاء أصدقائك.',
        ),
      ],
      myInvites: const [
        ProfileReferralInviteData(
          id: 1,
          userId: 22,
          name: 'Sara Mohamed',
          handle: 'sara.party',
          avatarAsset: 'assets/images/profile_store_friend_yara.png',
          status: 'registered',
          rewardUsd: 3,
          registeredAtLabel: '2026-05-07 12:30',
        ),
      ],
      rewardTransactions: const [
        ProfileReferralRewardTransactionData(
          id: 1,
          title: 'مكافأة تسجيل صديق',
          subtitle: 'تم تسجيل صديق جديد باستخدام كود الدعوة.',
          type: 'signup',
          amountUsd: 1,
          ratePercent: 100,
          status: 'available',
          createdAtLabel: '2026-05-07 12:30',
        ),
      ],
      leaderboard: const [
        ProfileReferralLeaderboardData(
          rank: 1,
          userId: 22,
          name: 'Sara Mohamed',
          handle: 'sara.party',
          avatarAsset: 'assets/images/profile_store_friend_yara.png',
          invitedCount: 15,
          rewardUsd: 1150.1,
        ),
      ],
    );
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(Object? value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
