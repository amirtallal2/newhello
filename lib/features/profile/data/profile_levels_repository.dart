import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class VipWalletData {
  const VipWalletData({
    required this.coinsBalance,
    required this.diamondsBalance,
  });

  final int coinsBalance;
  final int diamondsBalance;

  factory VipWalletData.fromJson(Map<String, dynamic> json) {
    return VipWalletData(
      coinsBalance: _asInt(json['coins_balance']),
      diamondsBalance: _asInt(json['diamonds_balance']),
    );
  }
}

class VipSubscriptionData {
  const VipSubscriptionData({
    required this.id,
    required this.levelId,
    required this.tierNumber,
    required this.tierName,
    required this.source,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
    required this.badgeAssetPath,
  });

  final int id;
  final int levelId;
  final int tierNumber;
  final String tierName;
  final String source;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String status;
  final String badgeAssetPath;

  bool get isActive {
    final expiry = expiresAt;
    return status == 'active' &&
        expiry != null &&
        expiry.isAfter(DateTime.now());
  }

  factory VipSubscriptionData.fromJson(Map<String, dynamic> json) {
    return VipSubscriptionData(
      id: _asInt(json['id']),
      levelId: _asInt(json['level_id']),
      tierNumber: _asInt(json['tier_number']),
      tierName: json['tier_name']?.toString() ?? 'VIP 0',
      source: json['source']?.toString() ?? 'self',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'inactive',
      badgeAssetPath:
          json['badge_asset_path']?.toString() ??
          'assets/images/profile_vip_icon.png',
    );
  }
}

class VipPrivilegeData {
  const VipPrivilegeData({
    required this.id,
    required this.unlockTier,
    required this.title,
    required this.description,
    required this.iconAssetPath,
    required this.isUnlocked,
    required this.status,
    required this.displayOrder,
  });

  final int id;
  final int unlockTier;
  final String title;
  final String description;
  final String iconAssetPath;
  final bool isUnlocked;
  final String status;
  final int displayOrder;

  factory VipPrivilegeData.fromJson(Map<String, dynamic> json) {
    return VipPrivilegeData(
      id: _asInt(json['id']),
      unlockTier: _asInt(json['unlock_tier'], fallback: 1),
      title: json['title']?.toString() ?? 'ميزة VIP',
      description: json['description']?.toString() ?? '',
      iconAssetPath:
          json['icon_asset_path']?.toString() ??
          'assets/images/profile_vip_icon.png',
      isUnlocked: _asBool(json['is_unlocked']),
      status: json['status']?.toString() ?? 'active',
      displayOrder: _asInt(json['display_order']),
    );
  }
}

class VipLevelData {
  const VipLevelData({
    required this.id,
    required this.tierNumber,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.priceCoins,
    required this.durationDays,
    required this.heroAssetPath,
    required this.badgeAssetPath,
    required this.status,
    required this.displayOrder,
    required this.unlockedPrivilegesCount,
    required this.privilegesTotalCount,
    required this.privileges,
  });

  final int id;
  final int tierNumber;
  final String name;
  final String subtitle;
  final String description;
  final int priceCoins;
  final int durationDays;
  final String heroAssetPath;
  final String badgeAssetPath;
  final String status;
  final int displayOrder;
  final int unlockedPrivilegesCount;
  final int privilegesTotalCount;
  final List<VipPrivilegeData> privileges;

  factory VipLevelData.fromJson(Map<String, dynamic> json) {
    return VipLevelData(
      id: _asInt(json['id']),
      tierNumber: _asInt(json['tier_number'], fallback: 1),
      name: json['name']?.toString() ?? 'VIP',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priceCoins: _asInt(json['price_coins']),
      durationDays: _asInt(json['duration_days'], fallback: 30),
      heroAssetPath:
          json['hero_asset_path']?.toString() ??
          'assets/images/profile_vip_icon.png',
      badgeAssetPath:
          json['badge_asset_path']?.toString() ??
          'assets/images/profile_vip_icon.png',
      status: json['status']?.toString() ?? 'active',
      displayOrder: _asInt(json['display_order']),
      unlockedPrivilegesCount: _asInt(json['unlocked_privileges_count']),
      privilegesTotalCount: _asInt(json['privileges_total_count']),
      privileges: (json['privileges'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) =>
                VipPrivilegeData.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class VipRecipientData {
  const VipRecipientData({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarAsset,
  });

  final int id;
  final String name;
  final String handle;
  final String avatarAsset;

  factory VipRecipientData.fromJson(Map<String, dynamic> json) {
    return VipRecipientData(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? 'Hallo Party User',
      handle: json['handle']?.toString() ?? '',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
    );
  }
}

class VipLevelsSummaryData {
  const VipLevelsSummaryData({
    required this.wallet,
    required this.currentSubscription,
    required this.levels,
    required this.coinAsset,
  });

  final VipWalletData wallet;
  final VipSubscriptionData? currentSubscription;
  final List<VipLevelData> levels;
  final String coinAsset;

  int get activeTierNumber => currentSubscription?.tierNumber ?? 0;

  int get defaultSelectedTierNumber {
    if (activeTierNumber > 0) {
      return activeTierNumber;
    }
    if (levels.isEmpty) {
      return 1;
    }
    return levels.last.tierNumber;
  }

  factory VipLevelsSummaryData.fromJson(Map<String, dynamic> json) {
    final subscriptionJson = json['current_subscription'];
    return VipLevelsSummaryData(
      wallet: VipWalletData.fromJson(
        Map<String, dynamic>.from(json['wallet'] as Map? ?? const {}),
      ),
      currentSubscription: subscriptionJson is Map
          ? VipSubscriptionData.fromJson(
              Map<String, dynamic>.from(subscriptionJson),
            )
          : null,
      levels: (json['levels'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => VipLevelData.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      coinAsset:
          json['coin_asset']?.toString() ??
          'assets/images/profile_store_coin_icon.png',
    );
  }
}

abstract class ProfileLevelsRepository {
  static ProfileLevelsRepository instance = LiveProfileLevelsRepository();

  Future<VipLevelsSummaryData> loadVipLevels();

  Future<VipLevelsSummaryData> activateVip({required int levelId});

  Future<VipLevelsSummaryData> sendVip({
    required int levelId,
    required int recipientUserId,
    required String recipientName,
  });

  Future<List<VipRecipientData>> searchVipRecipients({required String query});
}

final class LiveProfileLevelsRepository implements ProfileLevelsRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<VipLevelsSummaryData> loadVipLevels() async {
    final response = await _client.get(
      '/levels/vip',
      bearerToken: _authStore.authToken,
    );
    return VipLevelsSummaryData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<VipLevelsSummaryData> activateVip({required int levelId}) async {
    final response = await _client.post(
      '/levels/vip/activate',
      body: {'level_id': levelId},
      bearerToken: _authStore.authToken,
    );
    return VipLevelsSummaryData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<VipLevelsSummaryData> sendVip({
    required int levelId,
    required int recipientUserId,
    required String recipientName,
  }) async {
    final response = await _client.post(
      '/levels/vip/send',
      body: {
        'level_id': levelId,
        'recipient_user_id': recipientUserId,
        'recipient_name': recipientName,
      },
      bearerToken: _authStore.authToken,
    );
    return VipLevelsSummaryData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<List<VipRecipientData>> searchVipRecipients({
    required String query,
  }) async {
    final response = await _client.get(
      '/levels/vip/recipients?query=${Uri.encodeQueryComponent(query)}',
      bearerToken: _authStore.authToken,
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return (data['recipients'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => VipRecipientData.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}

final class FakeProfileLevelsRepository implements ProfileLevelsRepository {
  VipLevelsSummaryData _summary = _fakeSummary();

  @override
  Future<VipLevelsSummaryData> activateVip({required int levelId}) async {
    final level = _summary.levels.firstWhere(
      (item) => item.id == levelId,
      orElse: () => _summary.levels.last,
    );
    _summary = VipLevelsSummaryData(
      wallet: VipWalletData(
        coinsBalance: (_summary.wallet.coinsBalance - level.priceCoins)
            .clamp(0, 1 << 31)
            .toInt(),
        diamondsBalance: _summary.wallet.diamondsBalance,
      ),
      currentSubscription: VipSubscriptionData(
        id: 1,
        levelId: level.id,
        tierNumber: level.tierNumber,
        tierName: level.name,
        source: 'self',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: level.durationDays)),
        status: 'active',
        badgeAssetPath: level.badgeAssetPath,
      ),
      levels: _summary.levels,
      coinAsset: _summary.coinAsset,
    );
    return _summary;
  }

  @override
  Future<VipLevelsSummaryData> loadVipLevels() async => _summary;

  @override
  Future<List<VipRecipientData>> searchVipRecipients({
    required String query,
  }) async {
    const recipients = [
      VipRecipientData(
        id: 2,
        name: 'ياسمين محمد',
        handle: 'Yasmin.22',
        avatarAsset: 'assets/images/profile_store_friend_yara.png',
      ),
      VipRecipientData(
        id: 3,
        name: 'أحمد علي',
        handle: 'Ahmed.live',
        avatarAsset: 'assets/images/post_author_avatar.png',
      ),
    ];

    if (query.trim().isEmpty) {
      return recipients;
    }
    return recipients
        .where(
          (item) =>
              item.name.contains(query.trim()) ||
              item.handle.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
  }

  @override
  Future<VipLevelsSummaryData> sendVip({
    required int levelId,
    required int recipientUserId,
    required String recipientName,
  }) async {
    final level = _summary.levels.firstWhere(
      (item) => item.id == levelId,
      orElse: () => _summary.levels.last,
    );
    _summary = VipLevelsSummaryData(
      wallet: VipWalletData(
        coinsBalance: (_summary.wallet.coinsBalance - level.priceCoins)
            .clamp(0, 1 << 31)
            .toInt(),
        diamondsBalance: _summary.wallet.diamondsBalance,
      ),
      currentSubscription: _summary.currentSubscription,
      levels: _summary.levels,
      coinAsset: _summary.coinAsset,
    );
    return _summary;
  }
}

VipLevelsSummaryData _fakeSummary() {
  const iconPaths = [
    'assets/images/profile_store_frames_icon.png',
    'assets/images/profile_vip_icon.png',
    'assets/images/profile_badges_icon.png',
    'assets/images/profile_store_backgrounds_icon.png',
    'assets/images/room_gift_icon.png',
    'assets/images/profile_store_entry_effects_icon.png',
  ];
  const titles = [
    'المزيد من اعضاء غرفة',
    'وسام VIP',
    'اطار فاخر',
    'خلفية الغرفة',
    'هدايا حصرية',
    'العرض في القمة',
    'اخفاء حالة online',
    'منع المتابعة',
    'الحصول يومي علي 100 الماسة مجانا',
    'ترقية عالية السرعة',
    'رسائل ملونة',
    'قبعات الدردشة الغرفة',
    'اضاءة المايك',
    'خصم من المتجر',
    'مؤثرات الدخول',
    'غلاف الغرفة',
    'ارسال الصور في الشات',
    'خدمة العملاء',
  ];
  final privileges = <VipPrivilegeData>[
    for (var index = 0; index < titles.length; index++)
      VipPrivilegeData(
        id: index + 1,
        unlockTier: index < 6 ? 1 : (index ~/ 3) + 1,
        title: titles[index],
        description: 'ميزة VIP حقيقية قابلة للتحكم من لوحة الأدمن.',
        iconAssetPath: iconPaths[index % iconPaths.length],
        isUnlocked: true,
        status: 'active',
        displayOrder: index + 1,
      ),
  ];

  final levels = List.generate(6, (index) {
    final tier = index + 1;
    final unlocked = privileges
        .map(
          (item) => VipPrivilegeData(
            id: item.id,
            unlockTier: item.unlockTier,
            title: item.title,
            description: item.description,
            iconAssetPath: item.iconAssetPath,
            isUnlocked: item.unlockTier <= tier,
            status: item.status,
            displayOrder: item.displayOrder,
          ),
        )
        .toList();
    return VipLevelData(
      id: tier,
      tierNumber: tier,
      name: 'VIP $tier',
      subtitle: tier == 6 ? 'القمة الذهبية' : 'مستوى مميز',
      description: 'مميزات VIP حقيقية مرتبطة بالمحفظة ولوحة الأدمن.',
      priceCoins: tier * 10000,
      durationDays: 30,
      heroAssetPath: 'assets/images/profile_svip_icon.png',
      badgeAssetPath: 'assets/images/profile_vip_icon.png',
      status: 'active',
      displayOrder: tier,
      unlockedPrivilegesCount: unlocked.where((item) => item.isUnlocked).length,
      privilegesTotalCount: unlocked.length,
      privileges: unlocked,
    );
  });

  return VipLevelsSummaryData(
    wallet: const VipWalletData(coinsBalance: 600000, diamondsBalance: 25),
    currentSubscription: null,
    levels: levels,
    coinAsset: 'assets/images/profile_store_coin_icon.png',
  );
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
